# typed: strict
# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "yaml"

class CiPolicyTest < Minitest::Test
  CI_WORKFLOW = File.expand_path("../.github/workflows/ci.yml", __dir__).freeze
  AGENT_GUIDANCE = File.expand_path("../AGENTS.md", __dir__).freeze
  POLICY_WORKFLOW = File.expand_path("../.github/workflows/publisher-cask-policy.yml", __dir__).freeze

  def setup
    @source = File.read(POLICY_WORKFLOW)
    workflow = YAML.safe_load_file(POLICY_WORKFLOW, permitted_classes: [], aliases: false)
    @policy = workflow.fetch("jobs").fetch("verify")
    @top_level_permissions = workflow.fetch("permissions")
    @ci_source = File.read(CI_WORKFLOW)
    @ci = YAML.safe_load_file(CI_WORKFLOW, permitted_classes: [], aliases: false)
  end

  def test_policy_runs_from_the_trusted_main_branch
    assert_includes @source, "pull_request_target: # zizmor: ignore[dangerous-triggers]"
    assert_match(/pull_request_target:.*?branches:\n\s+- main/m, @source)
    refute_match(/^\s+workflow_dispatch:/, @source)

    checkout = step("Check out trusted policy")
    assert_equal "${{ github.event.pull_request.base.sha }}", checkout.fetch("with").fetch("ref")
    assert_equal false, checkout.fetch("with").fetch("persist-credentials")
    refute_includes checkout.fetch("with").values, "${{ github.event.pull_request.head.sha }}"
  end

  def test_policy_fetches_the_head_only_as_data_and_uses_the_local_verifier
    fetch = step("Fetch proposed commit as data")
    verification = step("Verify publisher cask and release provenance")

    assert_equal "git fetch --no-tags origin \"${HEAD_SHA}\"", fetch.fetch("run")
    assert_equal "${{ github.event.pull_request.head.sha }}", fetch.fetch("env").fetch("HEAD_SHA")
    assert_equal "ruby scripts/publisher_cask_policy.rb", verification.fetch("run")
    refute_includes @source, ".fleet-policy"
    refute_includes @source, "repository: starhaven-io/.github"
    refute_includes @source, "brew "
  end

  def test_policy_grants_only_read_permissions
    assert_equal(
      { "attestations" => "read", "contents" => "read" },
      @policy.fetch("permissions"),
    )
    assert_equal({}, @top_level_permissions)
  end

  def test_publisher_branch_routing_fails_closed_outside_reserved_namespaces
    non_strict_steps = ["Reject unexpected publisher branch", "Accept ordinary or fleet-sync change"]
    publisher_steps = @policy.fetch("steps").reject { |item| non_strict_steps.include?(item["name"]) }
    publisher_steps.each do |item|
      assert_equal "startsWith(github.event.pull_request.head.ref, 'bump-')", item.fetch("if")
    end

    reject_condition = step("Reject unexpected publisher branch").fetch("if")
    assert_equal(
      "( github.event.pull_request.user.id == 274951094 || " \
      "github.actor_id == '274951094' ) && " \
      "!startsWith(github.event.pull_request.head.ref, 'bump-')",
      reject_condition.gsub(/\s+/, " ").strip,
    )
    reject_step = step("Reject unexpected publisher branch")
    assert_equal "${{ github.event.pull_request.head.ref }}", reject_step.fetch("env").fetch("HEAD_REF")
    assert_includes reject_step.fetch("run"), "fleet-sync-*)"
    assert_includes reject_step.fetch("run"), "exit 1"

    accept_condition = step("Accept ordinary or fleet-sync change").fetch("if")
    assert_equal "${{ !startsWith(github.event.pull_request.head.ref, 'bump-') }}", accept_condition
    assert_includes @source, "PR_AUTHOR_ID: ${{ github.event.pull_request.user.id }}"
  end

  def test_fleet_sync_namespace_check_is_case_sensitive
    script = "set -euo pipefail\n#{step("Reject unexpected publisher branch").fetch("run")}"

    {
      "fleet-sync-v2026.09.04.1" => true,
      "feature/publisher-change" => false,
      "FLEET-SYNC-evil"          => false,
    }.each do |head_ref, expected_success|
      _stdout, _stderr, status = Open3.capture3({ "HEAD_REF" => head_ref }, "bash", "-c", script)
      assert_equal expected_success, status.success?, head_ref
    end
  end

  def test_general_ci_cannot_substitute_for_the_unique_publisher_check
    refute_includes @ci_source, "cask_policy"
    refute_includes @ci_source, "Publisher cask policy"
    assert_equal "Verify publisher cask", @policy.fetch("name")
  end

  def test_ci_uses_the_tap_name_returned_by_checkout_verification
    syntax = @ci.fetch("jobs").fetch("syntax")
    cask = @ci.fetch("jobs").fetch("cask")

    [syntax, cask].each do |job|
      verifier = job_step(job, "Verify active tap checkout")
      assert_equal "tap", verifier.fetch("id")
      assert_includes verifier.fetch("run"), 'echo "name=${resolved_tap}" >> "${GITHUB_OUTPUT}"'
    end

    syntax_check = job_step(syntax, "Verify tap syntax")
    assert_equal "${{ steps.tap.outputs.name }}", syntax_check.fetch("env").fetch("TAP_NAME")
    assert_includes syntax_check.fetch("run"), '"${TAP_NAME}"'

    ["Fetch cask", "Audit cask", "Install cask"].each do |name|
      cask_check = job_step(cask, name)
      assert_equal "${{ steps.tap.outputs.name }}", cask_check.fetch("env").fetch("TAP_NAME")
      assert_includes cask_check.fetch("run"), '"${TAP_NAME}/${CASK}"'
    end

    refute_match(/brew (?:test-bot|fetch|audit|install).*GITHUB_REPOSITORY/, @ci_source)
  end

  def test_guidance_uses_the_reported_job_context_name
    guidance = File.read(AGENT_GUIDANCE)

    assert_includes guidance, "Keep `Verify publisher cask` as a separately required"
    refute_includes guidance, "Publisher Cask Policy / Verify publisher cask"
  end

  private

  def step(name)
    @policy.fetch("steps").find { |item| item["name"] == name } || raise("missing step: #{name}")
  end

  def job_step(job, name)
    job.fetch("steps").find { |item| item["name"] == name } || raise("missing step: #{name}")
  end
end
