# typed: strict
# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "tmpdir"
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
    @concurrency = workflow.fetch("concurrency")
    @ci_source = File.read(CI_WORKFLOW)
    @ci = YAML.safe_load_file(CI_WORKFLOW, permitted_classes: [], aliases: false)
  end

  def test_policy_runs_from_the_trusted_main_branch
    assert_includes @source, "pull_request_target: # zizmor: ignore[dangerous-triggers]"
    assert_match(/pull_request_target:.*?branches:\n\s+- main/m, @source)
    refute_match(/^\s+workflow_dispatch:/, @source)

    checkout = step("Check out trusted policy")
    refute checkout.fetch("with").key?("ref"), "the trusted checkout must stay on the event's base branch tip"
    assert_equal 0, checkout.fetch("with").fetch("fetch-depth")
    assert_equal false, checkout.fetch("with").fetch("persist-credentials")
    refute_includes checkout.fetch("with").values, "${{ github.event.pull_request.head.sha }}"
  end

  def test_policy_takes_the_base_from_the_checkout_rather_than_the_payload
    base = step("Resolve the base branch tip")

    assert_equal "base", base.fetch("id")
    assert_includes base.fetch("run"), "git rev-parse --verify 'HEAD^{commit}'"
    assert_includes base.fetch("run"), 'echo "sha=${base_sha}" >> "${GITHUB_OUTPUT}"'
    assert_equal "${{ steps.base.outputs.sha }}", step("Verify publisher policy").fetch("env").fetch("BASE_SHA")
    refute_includes @source, "github.event.pull_request.base.sha"
  end

  def test_policy_fetches_the_head_only_as_data_and_uses_the_local_verifier
    fetch = step("Fetch proposed commit as data")
    verification = step("Verify publisher policy")

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

  def test_policy_never_cancels_an_in_progress_run
    assert_equal false, @concurrency.fetch("cancel-in-progress")
    assert_equal "publisher-cask-policy-${{ github.event.pull_request.number }}", @concurrency.fetch("group")
  end

  def test_publisher_branch_routing_fails_closed_outside_reserved_namespaces
    verifier_steps = @policy.fetch("steps").reject { |item| item["name"] == "Reject unexpected publisher branch" }
    verifier_steps.each do |item|
      refute item.key?("if"), "#{item.fetch("name")} must run for every pull request"
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

    verification_env = step("Verify publisher policy").fetch("env")
    assert_equal "${{ github.event.pull_request.user.id }}", verification_env.fetch("PR_AUTHOR_ID")
    assert_equal "${{ github.actor_id }}", verification_env.fetch("ACTOR_ID")
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

  def test_install_selection_exercises_the_affected_platforms
    resolver = job_step(@ci.fetch("jobs").fetch("syntax"), "Resolve cask list").fetch("run")
    script = <<~BASH + resolver
      set -euo pipefail
      git() {
        case "$1" in
          rev-parse) return 0 ;;
          diff) test "${!#}" = scripts/cask_matrix.rb && printf '%s' "$CHANGED_PATHS" ;;
          *) return 1 ;;
        esac
      }
    BASH
    Dir.mktmpdir do |dir|
      output = File.join(dir, "outputs")
      env = { "GITHUB_BASE_REF" => "main", "RUNNER_TEMP" => dir, "GITHUB_OUTPUT" => output }
      [
        ["pull_request", "Casks/midden.rb\n", "", "", "true", "true", 3],
        ["pull_request", ".github/workflows/ci.yml\n", "", "", "true", "true", 8],
        ["pull_request", "scripts/cask_matrix.rb\n", "", "", "true", "true", 8],
        ["pull_request", "", "", "", "false", "false", 0],
        ["workflow_dispatch", "", "brewy", "false", "true", "false", 1],
        ["workflow_dispatch", "", "brewy", "true", "true", "true", 1],
        ["push", "", "", "", "false", "false", 8],
      ].each do |event, changes, tokens, enabled, run_casks, install, count|
        File.write(output, "")
        scenario = { "GITHUB_EVENT_NAME" => event, "CHANGED_PATHS" => changes,
                     "INPUT_CASKS" => tokens, "INPUT_INSTALL" => enabled }
        log, status = Open3.capture2e(env.merge(scenario), "bash", "-c", script)
        assert_predicate status, :success?, log
        values = File.readlines(output, chomp: true).to_h { |line| line.split("=", 2) }
        entries = JSON.parse(values.fetch("matrix")).fetch("include")
        actual = [values.fetch("run_casks"), values.fetch("install"), entries.size]
        assert_equal [run_casks, install, count], actual, scenario.inspect
      end
    end
  end

  def test_installed_cli_requires_the_cask_version_and_all_three_completions
    job = @ci.fetch("jobs").fetch("cask")
    smoke = job_step(job, "Verify installed cask")
    assert_equal "steps.install.outcome == 'success'", smoke.fetch("if")
    assert_equal "always() && steps.install.outcome == 'success'", job_step(job, "Uninstall cask").fetch("if")

    Dir.mktmpdir do |prefix|
      files = %w[bin/midden etc/bash_completion.d/midden share/zsh/site-functions/_midden
                 share/fish/vendor_completions.d/midden.fish]
      files.each do |file|
        path = File.join(prefix, file)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "completion")
      end
      binary = File.join(prefix, "bin/midden")
      File.write(binary, "#!/bin/sh\ntest \"$1\" = --version && echo midden 1.0\n")
      File.chmod(0755, binary)
      env = { "TEST_PREFIX" => prefix, "CASK" => "midden", "TAP_NAME" => "example/tap", "EXPECTED" => "1.0" }
      script = <<~BASH + smoke.fetch("run")
        set -euo pipefail
        brew() {
          case "$1" in
            --prefix) echo "$TEST_PREFIX" ;;
            info) test "$4" = "$TAP_NAME/$CASK" && jq -n --arg version "$EXPECTED" '{casks: [{version: $version}]}' ;;
            *) return 1 ;;
          esac
        }
      BASH
      assert_predicate Open3.capture3(env, "bash", "-c", script).last, :success?
      refute_predicate Open3.capture3(env.merge("EXPECTED" => "2.0"), "bash", "-c", script).last, :success?
      File.truncate(File.join(prefix, files.last), 0)
      output, _, status = Open3.capture3(env, "bash", "-c", script)
      refute_predicate status, :success?
      assert_includes output, files.last
    end
  end

  private

  def step(name)
    @policy.fetch("steps").find { |item| item["name"] == name } || raise("missing step: #{name}")
  end

  def job_step(job, name)
    job.fetch("steps").find { |item| item["name"] == name } || raise("missing step: #{name}")
  end
end
