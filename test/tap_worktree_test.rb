# typed: strict
# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"

class TapWorktreeTest < Minitest::Test
  REPOSITORY_ROOT = File.expand_path("..", __dir__).freeze
  LINKER = File.join(REPOSITORY_ROOT, "scripts", "link_tap_worktree.rb").freeze
  VERIFIER = File.join(REPOSITORY_ROOT, "scripts", "verify_tap_worktree.rb").freeze
  SYNTAX_CHECK = File.join(REPOSITORY_ROOT, "scripts", "check_homebrew_syntax.rb").freeze

  def setup
    @directory = Dir.mktmpdir("tap-worktree-")
    @brew_repository = File.join(@directory, "homebréw[1]*? with spaces ")
    @bin = File.join(@directory, "bin")
    FileUtils.mkdir_p([@brew_repository, @bin])
    File.write(File.join(@bin, "brew"), <<~SH)
      #!/bin/sh
      case "$1" in
        --repository) printf '%s\\n' "#{@brew_repository}" ;;
        --repo) printf '%s/Library/Taps/%s/homebrew-%s\\n' "#{@brew_repository}" "${2%/*}" "${2#*/}" ;;
        test-bot) printf '%s\\n' "$*"; exit "${BREW_TEST_BOT_STATUS:-0}" ;;
        *) exit 64 ;;
      esac
    SH
    FileUtils.chmod(0755, File.join(@bin, "brew"))
    @env = { "PATH" => "#{@bin}:#{ENV.fetch("PATH")}", "BREW_TEST_BOT_STATUS" => nil }
  end

  def teardown
    FileUtils.rm_rf(@directory)
  end

  def test_links_and_verifies_checkout_under_private_alias
    stdout, stderr, status = Open3.capture3(
      @env,
      RbConfig.ruby, LINKER, "starhaven-worktree/tap", REPOSITORY_ROOT
    )
    assert status.success?, stderr
    assert_includes stdout, "HOMEBREW_TAP_NAME=starhaven-worktree/tap just check"

    stdout, stderr, status = Open3.capture3(
      @env,
      RbConfig.ruby, VERIFIER, REPOSITORY_ROOT, "starhaven-worktree/tap"
    )
    assert status.success?, stderr
    assert_equal "starhaven-worktree/tap", stdout.strip
  end

  def test_non_ascii_checkout_and_prefix_preserve_bytes_in_each_external_encoding
    checkout = File.join(@directory, "chéckout")
    FileUtils.mkdir_p(checkout)
    environment = @env.merge("LANG" => nil, "LC_ALL" => "C", "LC_CTYPE" => nil)
    requested_taps = %w[starhaven-worktree/tap starhaven-io/tap]
    %w[UTF-8 US-ASCII ISO-8859-1].each do |encoding|
      _stdout, stderr, status = Open3.capture3(
        environment, RbConfig.ruby, "-E#{encoding}", LINKER, "starhaven-worktree/tap", checkout, binmode: true
      )
      assert status.success?, "#{encoding}: #{stderr}"

      requested_taps.each do |requested|
        stdout, stderr, status = Open3.capture3(
          environment, RbConfig.ruby, "-E#{encoding}", VERIFIER, checkout, requested, binmode: true
        )
        assert status.success?, "#{encoding}: #{stderr}"
        assert_equal "starhaven-worktree/tap", stdout.strip
      end
    end
  end

  def test_empty_optional_arguments_preserve_the_shell_defaults
    [[], ["", ""]].each do |arguments|
      _stdout, stderr, status = Open3.capture3(
        @env, RbConfig.ruby, LINKER, *arguments, chdir: REPOSITORY_ROOT
      )
      assert status.success?, stderr

      stdout, stderr, status = Open3.capture3(
        @env, RbConfig.ruby, VERIFIER, *arguments, chdir: REPOSITORY_ROOT
      )
      assert status.success?, stderr
      assert_equal "starhaven-worktree/tap", stdout.strip
    end
  end

  def test_syntax_check_requires_nonempty_arguments
    [[], ["", "starhaven-worktree/tap"], [REPOSITORY_ROOT, ""]].each do |arguments|
      _stdout, stderr, status = Open3.capture3(@env, RbConfig.ruby, SYNTAX_CHECK, *arguments)
      refute status.success?
      assert_includes stderr, "usage: check_homebrew_syntax.rb CHECKOUT TAP_NAME"
    end
  end

  def test_refuses_to_replace_an_existing_tap
    tap_path = File.join(@brew_repository, "Library/Taps/existing/homebrew-tap")
    FileUtils.mkdir_p(tap_path)

    _stdout, stderr, status = Open3.capture3(
      @env,
      RbConfig.ruby, LINKER, "existing/tap", REPOSITORY_ROOT
    )
    refute status.success?
    assert_includes stderr, "refusing to replace existing path"
  end

  def test_rejects_invalid_aliases
    _stdout, stderr, status = Open3.capture3(
      @env,
      RbConfig.ruby, LINKER, "../tap", REPOSITORY_ROOT
    )
    refute status.success?
    assert_includes stderr, "invalid tap name"

    _stdout, stderr, status = Open3.capture3(
      @env,
      RbConfig.ruby, VERIFIER, REPOSITORY_ROOT, "--help"
    )
    refute status.success?
    assert_includes stderr, "invalid tap name"
  end

  def test_refuses_to_claim_the_canonical_owner
    canonical_path = File.join(@brew_repository, "Library/Taps/starhaven-io/homebrew-tap")
    _stdout, stderr, status = Open3.capture3(
      @env,
      RbConfig.ruby, LINKER, "starhaven-io/tap", REPOSITORY_ROOT
    )

    refute status.success?
    assert_includes stderr, "refusing to claim the canonical starhaven-io owner"
    refute File.symlink?(canonical_path)
  end

  def test_refuses_a_symlinked_private_owner_that_targets_the_canonical_owner
    taps_root = File.join(@brew_repository, "Library/Taps")
    canonical_owner = File.join(taps_root, "starhaven-io")
    private_owner = File.join(taps_root, "private")
    FileUtils.mkdir_p(canonical_owner)
    File.symlink(canonical_owner, private_owner)

    _stdout, stderr, status = Open3.capture3(
      @env,
      RbConfig.ruby, LINKER, "private/tap", REPOSITORY_ROOT
    )

    refute status.success?
    assert_includes stderr, "refusing symlinked tap owner path"
    refute File.symlink?(File.join(canonical_owner, "homebrew-tap"))
  end

  def test_discovers_unique_private_alias_when_requested_tap_points_elsewhere
    canonical_path = File.join(@brew_repository, "Library/Taps/starhaven-io/homebrew-tap")
    FileUtils.mkdir_p(canonical_path)
    _stdout, stderr, status = Open3.capture3(
      @env,
      RbConfig.ruby, LINKER, "starhaven-worktree/tap", REPOSITORY_ROOT
    )
    assert status.success?, stderr

    stdout, stderr, status = Open3.capture3(
      @env,
      RbConfig.ruby, VERIFIER, REPOSITORY_ROOT, "starhaven-io/tap"
    )

    assert status.success?, stderr
    assert_equal "starhaven-worktree/tap", stdout.strip
  end

  def test_rejects_ambiguous_private_alias_discovery
    %w[starhaven-first/tap starhaven-second/tap].each do |tap_name|
      _stdout, stderr, status = Open3.capture3(
        @env,
        RbConfig.ruby, LINKER, tap_name, REPOSITORY_ROOT
      )
      assert status.success?, stderr
    end

    _stdout, stderr, status = Open3.capture3(
      @env,
      RbConfig.ruby, VERIFIER, REPOSITORY_ROOT, "starhaven-io/tap"
    )

    refute status.success?
    assert_includes stderr, "multiple private tap aliases resolve to this checkout"
    assert_includes stderr, "select one with HOMEBREW_TAP_NAME"
  end

  def test_discovery_ignores_canonical_owner_aliases
    canonical_path = File.join(@brew_repository, "Library/Taps/starhaven-io/homebrew-alias")
    FileUtils.mkdir_p(File.dirname(canonical_path))
    File.symlink(REPOSITORY_ROOT, canonical_path)

    _stdout, stderr, status = Open3.capture3(
      @env, RbConfig.ruby, VERIFIER, REPOSITORY_ROOT, "missing/tap"
    )
    refute status.success?
    assert_includes stderr, "run 'just link-tap' before retrying"

    _stdout, stderr, status = Open3.capture3(
      @env, RbConfig.ruby, LINKER, "starhaven-worktree/tap", REPOSITORY_ROOT
    )
    assert status.success?, stderr
    stdout, stderr, status = Open3.capture3(
      @env, RbConfig.ruby, VERIFIER, REPOSITORY_ROOT, "missing/tap"
    )
    assert status.success?, stderr
    assert_equal "starhaven-worktree/tap", stdout.strip
  end

  def test_ignores_broken_alias_when_discovering_the_checkout
    broken_path = File.join(@brew_repository, "Library/Taps/broken/homebrew-tap")
    FileUtils.mkdir_p(File.dirname(broken_path))
    File.symlink(File.join(@directory, "missing-checkout"), broken_path)
    _stdout, stderr, status = Open3.capture3(
      @env, RbConfig.ruby, LINKER, "starhaven-worktree/tap", REPOSITORY_ROOT
    )
    assert status.success?, stderr

    stdout, stderr, status = Open3.capture3(
      @env, RbConfig.ruby, VERIFIER, REPOSITORY_ROOT, "starhaven-io/tap"
    )

    assert status.success?, stderr
    assert_equal "starhaven-worktree/tap", stdout.strip
  end

  def test_syntax_check_fails_without_homebrew
    path = "/usr/bin:/bin"
    _stdout, stderr, status = Open3.capture3(
      { "PATH" => path }, RbConfig.ruby, SYNTAX_CHECK, REPOSITORY_ROOT, "starhaven-worktree/tap"
    )

    refute status.success?
    assert_includes stderr, "brew not found"
  end

  def test_syntax_check_fails_when_tap_points_elsewhere
    _stdout, stderr, status = Open3.capture3(
      @env, RbConfig.ruby, SYNTAX_CHECK, REPOSITORY_ROOT, "starhaven-worktree/tap"
    )

    refute status.success?
    assert_includes stderr, "Homebrew is not linked to this checkout"
  end

  def test_syntax_check_runs_test_bot_for_linked_alias
    _stdout, stderr, status = Open3.capture3(
      @env, RbConfig.ruby, LINKER, "starhaven-worktree/tap", REPOSITORY_ROOT
    )
    assert status.success?, stderr

    _stdout, stderr, status = Open3.capture3(
      @env, RbConfig.ruby, SYNTAX_CHECK, REPOSITORY_ROOT, "starhaven-worktree/tap"
    )
    assert status.success?, stderr
  end

  def test_syntax_check_ignores_extra_arguments
    _stdout, stderr, status = Open3.capture3(
      @env, RbConfig.ruby, LINKER, "starhaven-worktree/tap", REPOSITORY_ROOT
    )
    assert status.success?, stderr

    [["ignored"], ["", "--help"]].each do |extra_arguments|
      stdout, stderr, status = Open3.capture3(
        @env, RbConfig.ruby, SYNTAX_CHECK, REPOSITORY_ROOT, "starhaven-worktree/tap", *extra_arguments
      )
      assert status.success?, stderr
      assert_equal "test-bot --tap starhaven-worktree/tap --only-tap-syntax\n", stdout
    end
  end

  def test_syntax_check_preserves_test_bot_failure_status
    _stdout, stderr, status = Open3.capture3(
      @env, RbConfig.ruby, LINKER, "starhaven-worktree/tap", REPOSITORY_ROOT
    )
    assert status.success?, stderr

    stdout, _stderr, status = Open3.capture3(
      @env.merge("BREW_TEST_BOT_STATUS" => "42"),
      RbConfig.ruby, SYNTAX_CHECK, REPOSITORY_ROOT, "starhaven-worktree/tap"
    )
    assert_equal 42, status.exitstatus
    assert_equal "test-bot --tap starhaven-worktree/tap --only-tap-syntax\n", stdout
  end

  def test_syntax_check_uses_discovered_private_alias
    canonical_path = File.join(@brew_repository, "Library/Taps/starhaven-io/homebrew-tap")
    FileUtils.mkdir_p(canonical_path)
    _stdout, stderr, status = Open3.capture3(
      @env, RbConfig.ruby, LINKER, "starhaven-worktree/tap", REPOSITORY_ROOT
    )
    assert status.success?, stderr

    stdout, stderr, status = Open3.capture3(
      @env, RbConfig.ruby, SYNTAX_CHECK, REPOSITORY_ROOT, "starhaven-io/tap"
    )

    assert status.success?, stderr
    assert_includes stdout, "test-bot --tap starhaven-worktree/tap --only-tap-syntax"
  end
end
