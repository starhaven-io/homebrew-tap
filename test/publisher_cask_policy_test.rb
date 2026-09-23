# typed: strict
# frozen_string_literal: true

require "digest"
require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"

require_relative "../scripts/publisher_cask_policy"

class PublisherCaskPolicyTest < Minitest::Test
  class FakeGitHubClient
    attr_reader :attestations

    def initialize(plan, contents:, release_changes: {}, fail_attestation: false)
      @plan = plan
      @contents = contents
      @fail_attestation = fail_attestation
      @attestations = []
      @assets_by_id = {}
      assets = plan.fetch("artifacts").each_with_index.map do |artifact, index|
        id = index + 100
        content = contents.fetch(artifact.fetch("name"))
        @assets_by_id[id] = content
        {
          "id"                   => id,
          "name"                 => artifact.fetch("name"),
          "digest"               => "sha256:#{artifact.fetch("sha256")}",
          "size"                 => content.bytesize,
          "browser_download_url" => "https://github.com/#{plan.fetch("repository")}/releases/download/#{plan.fetch("tag")}/#{artifact.fetch("name")}",
        }
      end
      @release = {
        "tag_name"     => plan.fetch("tag"),
        "draft"        => false,
        "prerelease"   => false,
        "published_at" => "2026-09-04T00:00:00Z",
        "assets"       => assets,
      }.merge(release_changes)
    end

    def release(repository, tag)
      raise "unexpected repository" if repository != @plan.fetch("repository")
      raise "unexpected tag" if tag != @plan.fetch("tag")

      @release
    end

    def resolve_tag_commit(repository, tag)
      release(repository, tag)
      "1" * 40
    end

    def download_asset(repository, asset_id, destination)
      raise "unexpected repository" if repository != @plan.fetch("repository")

      File.binwrite(destination, @assets_by_id.fetch(asset_id))
    end

    def verify_attestation(path, repository, source_digest)
      raise PublisherCaskPolicy::PolicyError, "attestation rejected" if @fail_attestation

      @attestations << [File.basename(path), repository, source_digest]
    end
  end

  class RecordingGitHubClient < PublisherCaskPolicy::GitHubClient
    attr_reader :commands

    def initialize
      super
      @commands = []
    end

    private

    def run!(*command)
      @commands << command
      ""
    end
  end

  def setup
    @root = Dir.mktmpdir("publisher-cask-policy-")
    FileUtils.mkdir_p(File.join(@root, "Casks"))
    git("init", "--quiet", "--initial-branch=main")
    git("config", "user.name", "Tap Test")
    git("config", "user.email", "tap-test@example.com")
    git("config", "commit.gpgsign", "false")
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def test_policy_inventory_matches_every_cask_in_the_tap
    repository_root = File.expand_path("..", __dir__)
    casks = Dir[File.join(repository_root, "Casks/*.rb")].map { |path| File.basename(path, ".rb") }.sort

    assert_equal casks, PublisherCaskPolicy::PRODUCTS.keys.sort
  end

  def test_publisher_parser_accepts_every_current_cask
    repository_root = File.expand_path("..", __dir__)

    PublisherCaskPolicy::PRODUCTS.each_key do |token|
      source = File.binread(File.join(repository_root, "Casks", "#{token}.rb"))
      parsed = PublisherCaskPolicy::SourceParser.new(source, token).parse

      refute_empty parsed.fetch(:artifacts), token
    end
  end

  def test_verifies_established_publisher_title_and_release_provenance
    old_content = "old release"
    new_content = "new release"
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", Digest::SHA256.hexdigest(old_content)))
    head = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.1.0", Digest::SHA256.hexdigest(new_content)))
    plan = build_plan(base, head, "brewy", "1.1.0")
    client = FakeGitHubClient.new(plan, contents: { "Brewy-1.1.0.zip" => new_content })

    result = PublisherCaskPolicy.verify!(
      root:   @root,
      env:    publisher_environment(base, head, "brewy", "1.1.0"),
      client: client,
    )

    assert_equal plan, result.fetch("plan")
    assert_equal 1, client.attestations.length
    assert_equal "starhaven-io/Brewy", client.attestations.first[1]
    assert_equal "1" * 40, client.attestations.first[2]
  end

  def test_accepts_conventional_publisher_title_without_weakening_identity_binding
    content = "conventional release"
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", "a" * 64))
    head = commit_cask(
      "brewy",
      simple_cask("brewy", "Brewy", "1.1.0", Digest::SHA256.hexdigest(content)),
    )
    plan = build_plan(base, head, "brewy", "1.1.0")
    client = FakeGitHubClient.new(plan, contents: { "Brewy-1.1.0.zip" => content })
    environment = publisher_environment(base, head, "brewy", "1.1.0")
    environment["PR_TITLE"] = "chore(cask): update brewy to 1.1.0"

    result = PublisherCaskPolicy.verify_pr!(root: @root, env: environment, client: client)

    assert_equal "1.1.0", result.fetch("plan").fetch("version")
  end

  def test_builds_exact_multi_platform_asset_bindings
    base = commit_cask("pinprick", platform_cask("pinprick", "1.0.0", "a" * 64, "b" * 64, "c" * 64))
    head = commit_cask("pinprick", platform_cask("pinprick", "1.1.0", "d" * 64, "e" * 64, "f" * 64))

    plan = build_plan(base, head, "pinprick", "1.1.0")

    assert_equal(
      [
        ["macos_arm64", "pinprick-1.1.0-aarch64-apple-darwin.tar.gz", "d" * 64],
        ["linux_arm64", "pinprick-1.1.0-aarch64-unknown-linux-gnu.tar.gz", "e" * 64],
        ["linux_x86_64", "pinprick-1.1.0-x86_64-unknown-linux-gnu.tar.gz", "f" * 64],
      ],
      plan.fetch("artifacts").map { |artifact| artifact.values_at("selector", "name", "sha256") },
    )
  end

  def test_rejects_legacy_nested_platform_checksums
    source = legacy_platform_cask("pinprick", "1.0.0", "a" * 64, "b" * 64, "c" * 64)

    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      PublisherCaskPolicy::SourceParser.new(source, "pinprick").parse
    end
    assert_includes error.message, "unsupported sha256 stanza"
  end

  def test_rejects_platform_cask_without_macos_block
    source = platform_cask("pinprick", "1.0.0", "a" * 64, "b" * 64, "c" * 64)
             .sub("  on_macos do\n    depends_on arch: :arm64\n  end\n\n", "")

    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      PublisherCaskPolicy::SourceParser.new(source, "pinprick").parse
    end
    assert_includes error.message, "requires an on_macos block"
  end

  def test_rejects_platform_cask_without_macos_arm64_constraint
    source = platform_cask("pinprick", "1.0.0", "a" * 64, "b" * 64, "c" * 64)
             .sub("    depends_on arch: :arm64\n", "")

    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      PublisherCaskPolicy::SourceParser.new(source, "pinprick").parse
    end
    assert_includes error.message, "requires an arm64 constraint"
  end

  def test_rejects_cask_code_or_url_changes
    base_source = simple_cask("brewy", "Brewy", "1.0.0", "a" * 64)
    base = commit_cask("brewy", base_source)
    modified_source = simple_cask("brewy", "Brewy", "1.1.0", "b" * 64).sub(
      "  binary \"brewy\"\n",
      "  binary \"brewy\"\n  postflight { system_command \"curl\" }\n",
    )
    head = commit_cask("brewy", modified_source)

    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      build_plan(base, head, "brewy", "1.1.0")
    end
    assert_includes error.message, "only version and sha256"

    git("reset", "--hard", base)
    changed_url = simple_cask("brewy", "Brewy", "1.1.0", "b" * 64).sub("starhaven-io/Brewy", "attacker/example")
    head = commit_cask("brewy", changed_url)
    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      build_plan(base, head, "brewy", "1.1.0")
    end
    assert_includes error.message, "not bound"
  end

  def test_rejects_version_mismatch_and_downgrade
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "2.0.0", "a" * 64))
    head = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.9.0", "b" * 64))

    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      build_plan(base, head, "brewy", "1.9.0")
    end
    assert_includes error.message, "advance monotonically"

    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      build_plan(base, head, "brewy", "3.0.0")
    end
    assert_includes error.message, "does not match"
  end

  def test_rejects_selector_checksum_swaps
    base = commit_cask("pinprick", platform_cask("pinprick", "1.0.0", "a" * 64, "b" * 64, "c" * 64))
    head = commit_cask("pinprick", platform_cask("pinprick", "1.1.0", "d" * 64, "e" * 64, "f" * 64))
    plan = build_plan(base, head, "pinprick", "1.1.0")
    contents = plan.fetch("artifacts").to_h { |artifact| [artifact.fetch("name"), artifact.fetch("selector")] }
    client = FakeGitHubClient.new(plan, contents: contents)
    release = client.release(plan.fetch("repository"), plan.fetch("tag"))
    release.fetch("assets")[1]["digest"] = "sha256:#{"f" * 64}"
    release.fetch("assets")[2]["digest"] = "sha256:#{"e" * 64}"

    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      PublisherCaskPolicy::ReleaseVerifier.new(client: client).validate_release!(plan, release)
    end
    assert_includes error.message, "linux_arm64"
  end

  def test_rejects_substituted_download_and_missing_attestation
    content = "trusted release"
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", "a" * 64))
    head = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.1.0", Digest::SHA256.hexdigest(content)))
    plan = build_plan(base, head, "brewy", "1.1.0")

    client = FakeGitHubClient.new(plan, contents: { "Brewy-1.1.0.zip" => "same-size-wrong!" })
    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      PublisherCaskPolicy::ReleaseVerifier.new(client: client).verify!(plan)
    end
    assert_includes error.message, "Downloaded checksum"

    client = FakeGitHubClient.new(
      plan,
      contents:         { "Brewy-1.1.0.zip" => content },
      fail_attestation: true,
    )
    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      PublisherCaskPolicy::ReleaseVerifier.new(client: client).verify!(plan)
    end
    assert_includes error.message, "attestation rejected"
  end

  def test_attestation_binds_release_workflow_main_tag_commit_and_hosted_runners
    client = RecordingGitHubClient.new
    client.verify_attestation("/downloads/0-pinprick.tar.gz", "starhaven-io/pinprick", "1" * 40)

    assert_equal(
      [[
        "gh", "attestation", "verify", "/downloads/0-pinprick.tar.gz",
        "--repo", "starhaven-io/pinprick",
        "--signer-workflow", "github.com/starhaven-io/pinprick/.github/workflows/release.yml",
        "--source-ref", "refs/heads/main",
        "--source-digest", "1" * 40,
        "--deny-self-hosted-runners"
      ]],
      client.commands,
    )
  end

  def test_rejects_unpublished_or_prerelease_assets
    content = "stable release"
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", "a" * 64))
    head = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.1.0", Digest::SHA256.hexdigest(content)))
    plan = build_plan(base, head, "brewy", "1.1.0")

    [{ "draft" => true }, { "prerelease" => true }, { "published_at" => nil }].each do |release_changes|
      client = FakeGitHubClient.new(
        plan,
        contents:        { "Brewy-1.1.0.zip" => content },
        release_changes: release_changes,
      )

      error = assert_raises(PublisherCaskPolicy::PolicyError, release_changes.inspect) do
        PublisherCaskPolicy::ReleaseVerifier.new(client: client).verify!(plan)
      end
      assert_includes error.message, "published, stable"
    end
  end

  def test_rejects_asset_url_and_size_mismatches
    content = "bound release"
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", "a" * 64))
    head = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.1.0", Digest::SHA256.hexdigest(content)))
    plan = build_plan(base, head, "brewy", "1.1.0")

    {
      "browser_download_url" => ["https://github.com/starhaven-io/Brewy/releases/download/1.1.0/Other.zip",
                                 "Release download URL does not match"],
      "size"                 => [content.bytesize + 1, "Downloaded size does not match"],
    }.each do |field, (value, message)|
      client = FakeGitHubClient.new(plan, contents: { "Brewy-1.1.0.zip" => content })
      client.release(plan.fetch("repository"), plan.fetch("tag")).fetch("assets").first[field] = value

      error = assert_raises(PublisherCaskPolicy::PolicyError, field) do
        PublisherCaskPolicy::ReleaseVerifier.new(client: client).verify!(plan)
      end
      assert_includes error.message, message
    end
  end

  def test_rejects_pull_request_metadata_outside_the_publisher_contract
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", "a" * 64))
    head = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.1.0", "b" * 64))

    {
      "REPOSITORY"      => ["attacker/homebrew-tap", "same-repository branch targeting main"],
      "HEAD_REPOSITORY" => ["attacker/homebrew-tap", "same-repository branch targeting main"],
      "BASE_REF"        => ["release", "same-repository branch targeting main"],
      "HEAD_REF"        => ["bump-brewy-1.2.0", "branch, title, and cask path do not agree"],
    }.each do |name, (value, message)|
      environment = publisher_environment(base, head, "brewy", "1.1.0").merge(name => value)

      error = assert_raises(PublisherCaskPolicy::PolicyError, name) do
        PublisherCaskPolicy.verify_pr!(root: @root, env: environment, client: Object.new)
      end
      assert_includes error.message, message
    end
  end

  def test_rejects_human_authored_reserved_bump_and_multi_file_change
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", "a" * 64))
    head = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.1.0", "b" * 64))
    environment = publisher_environment(base, head, "brewy", "1.1.0")
    environment["PR_AUTHOR_ID"] = "12345"

    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      PublisherCaskPolicy.verify_pr!(root: @root, env: environment, client: Object.new)
    end
    assert_includes error.message, "authored by another identity"

    environment["PR_AUTHOR_ID"] = PublisherCaskPolicy::BOT_USER_ID
    File.write(File.join(@root, "README.md"), "extra\n")
    git("add", "README.md")
    git("commit", "--quiet", "-m", "extra file")
    environment["HEAD_SHA"] = git("rev-parse", "HEAD").strip
    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      PublisherCaskPolicy.verify_pr!(root: @root, env: environment, client: Object.new)
    end
    assert_includes error.message, "exactly one existing cask"
  end

  def test_rejects_symlinked_cask_blob
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", "a" * 64))
    path = File.join(@root, "Casks", "brewy.rb")
    File.unlink(path)
    File.write(File.join(@root, "outside.rb"), simple_cask("brewy", "Brewy", "1.1.0", "b" * 64))
    File.symlink("../outside.rb", path)
    git("add", "Casks/brewy.rb", "outside.rb")
    git("commit", "--quiet", "-m", "symlink cask")
    head = git("rev-parse", "HEAD").strip

    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      build_plan(base, head, "brewy", "1.1.0")
    end
    assert_includes error.message, "regular non-executable file"
  end

  def test_rejects_oversized_cask_blob_before_parsing
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", "a" * 64))
    oversized = simple_cask("brewy", "Brewy", "1.1.0", "b" * 64) + ("# padding\n" * 8_000)
    head = commit_cask("brewy", oversized)

    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      build_plan(base, head, "brewy", "1.1.0")
    end
    assert_includes error.message, "unexpectedly large"
  end

  def test_fleet_sync_may_not_change_publisher_owned_paths
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", "a" * 64))

    {
      "Casks/brewy.rb"                              => simple_cask("brewy", "Brewy", "1.0.0", "b" * 64),
      "scripts/publisher_cask_policy.rb"            => "# weakened\n",
      "test/publisher_cask_policy_test.rb"          => "# removed\n",
      ".ruby-version"                               => "4.0.7\n",
      ".github/workflows/publisher-cask-policy.yml" => "name: weakened\n",
    }.each do |path, content|
      git("reset", "--quiet", "--hard", base)
      head = commit_files(path => content)

      error = assert_raises(PublisherCaskPolicy::PolicyError, path) do
        PublisherCaskPolicy.verify!(root: @root, env: fleet_sync_environment(base, head))
      end
      assert_includes error.message, path
    end
  end

  def test_fleet_sync_may_not_move_a_cask_out_of_the_tap
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", "a" * 64))
    git("mv", "Casks/brewy.rb", "brewy.rb")
    git("commit", "--quiet", "-m", "move cask")
    head = git("rev-parse", "HEAD").strip

    error = assert_raises(PublisherCaskPolicy::PolicyError) do
      PublisherCaskPolicy.verify!(root: @root, env: fleet_sync_environment(base, head))
    end
    assert_includes error.message, "Casks/brewy.rb"
  end

  def test_fleet_sync_may_change_shared_tooling
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", "a" * 64))
    head = commit_files(
      ".github/workflows/ci.yml" => "name: CI\n",
      ".githooks/pre-push"       => "#!/bin/sh\n",
      "justfile"                 => "check:\n",
    )

    result = PublisherCaskPolicy.verify!(root: @root, env: fleet_sync_environment(base, head))

    assert_equal(
      [".githooks/pre-push", ".github/workflows/ci.yml", "justfile"],
      result.fetch("fleet_sync").fetch("paths").sort,
    )
  end

  def test_rejects_branches_outside_the_reserved_namespaces
    base = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.0.0", "a" * 64))
    head = commit_cask("brewy", simple_cask("brewy", "Brewy", "1.1.0", "b" * 64))

    ["feature/bump-brewy-1.1.0", "Bump-brewy-1.1.0", "FLEET-SYNC-v2026.09.23.1"].each do |head_ref|
      environment = publisher_environment(base, head, "brewy", "1.1.0").merge("HEAD_REF" => head_ref)

      error = assert_raises(PublisherCaskPolicy::PolicyError, head_ref) do
        PublisherCaskPolicy.verify!(root: @root, env: environment, client: Object.new)
      end
      assert_includes error.message, "outside the reserved publisher namespaces"
    end
  end

  private

  def commit_files(files)
    files.each do |path, content|
      absolute_path = File.join(@root, path)
      FileUtils.mkdir_p(File.dirname(absolute_path))
      File.write(absolute_path, content)
      git("add", path)
    end
    git("commit", "--quiet", "-m", "fleet sync")
    git("rev-parse", "HEAD").strip
  end

  def fleet_sync_environment(base, head)
    { "BASE_SHA" => base, "HEAD_SHA" => head, "HEAD_REF" => "fleet-sync-v2026.09.23.1" }
  end

  def simple_cask(token, product, version, sha256)
    <<~RUBY
      cask "#{token}" do
        version "#{version}"
        sha256 "#{sha256}"

        url "https://github.com/starhaven-io/#{product}/releases/download/\#{version}/#{product}-\#{version}.zip"
        name "#{product}"
        desc "Test cask"
        homepage "https://github.com/starhaven-io/#{product}"

        binary "#{token}"
      end
    RUBY
  end

  def platform_cask(token, version, macos_sha, linux_arm_sha, linux_intel_sha)
    <<~RUBY
      cask "#{token}" do
        arch arm: "aarch64", intel: "x86_64"
        os macos: "apple-darwin", linux: "unknown-linux-gnu"

        version "#{version}"
        sha256 arm:          "#{macos_sha}",
               arm64_linux:  "#{linux_arm_sha}",
               x86_64_linux: "#{linux_intel_sha}"

        on_macos do
          depends_on arch: :arm64
        end

        url "https://github.com/starhaven-io/#{token}/releases/download/v\#{version}/#{token}-\#{version}-\#{arch}-\#{os}.tar.gz"
        name "#{token}"
        desc "Test cask"
        homepage "https://github.com/starhaven-io/#{token}"

        binary "#{token}"
      end
    RUBY
  end

  def legacy_platform_cask(token, version, macos_sha, linux_arm_sha, linux_intel_sha)
    <<~RUBY
      cask "#{token}" do
        arch arm: "aarch64", intel: "x86_64"
        os macos: "apple-darwin", linux: "unknown-linux-gnu"

        version "#{version}"

        on_macos do
          sha256 "#{macos_sha}"

          depends_on arch: :arm64
        end
        on_linux do
          sha256 arm64_linux:  "#{linux_arm_sha}",
                 x86_64_linux: "#{linux_intel_sha}"
        end

        url "https://github.com/starhaven-io/#{token}/releases/download/v\#{version}/#{token}-\#{version}-\#{arch}-\#{os}.tar.gz"
        name "#{token}"
        desc "Test cask"
        homepage "https://github.com/starhaven-io/#{token}"

        binary "#{token}"
      end
    RUBY
  end

  def commit_cask(token, source)
    File.write(File.join(@root, "Casks", "#{token}.rb"), source)
    git("add", "Casks/#{token}.rb")
    git("commit", "--quiet", "-m", "#{token} update")
    git("rev-parse", "HEAD").strip
  end

  def build_plan(base, head, token, version)
    PublisherCaskPolicy.build_plan(
      root:             @root,
      base_ref:         base,
      head_ref:         head,
      token:            token,
      expected_version: version,
    )
  end

  def publisher_environment(base, head, token, version)
    {
      "BASE_REF"        => "main",
      "BASE_SHA"        => base,
      "HEAD_REF"        => "bump-#{token}-#{version}",
      "HEAD_REPOSITORY" => PublisherCaskPolicy::TAP_REPOSITORY,
      "HEAD_SHA"        => head,
      "PR_AUTHOR_ID"    => PublisherCaskPolicy::BOT_USER_ID,
      "PR_TITLE"        => "#{token} #{version}",
      "REPOSITORY"      => PublisherCaskPolicy::TAP_REPOSITORY,
    }
  end

  def git(*arguments)
    stdout, stderr, status = Open3.capture3("git", "-C", @root, *arguments)
    raise stderr unless status.success?

    stdout
  end
end
