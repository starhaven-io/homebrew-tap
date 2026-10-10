# typed: strict
# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"

class CheckContractTest < Minitest::Test
  JUSTFILE = File.expand_path("../justfile", __dir__).freeze

  def test_unlinked_homebrew_coverage_fails_the_aggregate_check
    recipe = File.read(JUSTFILE).match(/^check:\n(?<body>(?:    .*\n|\n)*)/)&.[](:body)

    refute_nil recipe
    assert_includes recipe, "ruby scripts/check.rb"
    checks = File.read(File.expand_path("../scripts/check.rb", __dir__))
    assert_includes checks, 'run.call("test-bot", RbConfig.ruby, "scripts/check_homebrew_syntax.rb"'
    assert_includes checks, 'run.call("zizmor", "zizmor", "--strict-collection", "--persona", "auditor", ".")'
    refute_includes recipe, "run zizmor zizmor ."
    refute_includes recipe, "test-bot skipped"
  end

  def test_user_controlled_just_values_are_shell_quoted
    source = File.read(JUSTFILE)

    assert_includes source, "quote(tap_name)"
    assert_includes source, "quote(token)"
    assert_includes source, "quote(alias)"
    refute_match(/\{\{\s+(?:tap_name|token|alias)\s+\}\}/, source)
  end

  def with_check_fixture
    Dir.mktmpdir("tap-check-") do |root|
      scripts = File.join(root, "scripts")
      bin = File.join(root, "bin")
      FileUtils.mkdir_p([scripts, bin])
      FileUtils.cp(File.expand_path("../scripts/check.rb", __dir__), scripts)
      File.write(File.join(scripts, "check_homebrew_syntax.rb"), <<~RUBY)
        File.open(ENV.fetch("CHECK_LOG"), "a") { |file| file.puts "test-bot" }
        exit(ENV["FAIL_CHECK"] == "test-bot" ? 42 : 0)
      RUBY
      %w[git bundle shellcheck zizmor pinprick lychee].each do |tool|
        path = File.join(bin, tool)
        File.write(path, <<~SH)
          #!/bin/sh
          tool="${0##*/}"
          printf '%s\\n' "$tool" >> "$CHECK_LOG"
          if [ "$FAIL_CHECK" = "$tool" ]; then exit 42; fi
        SH
        FileUtils.chmod(0755, path)
      end
      environment = { "PATH" => bin, "CHECK_LOG" => File.join(root, "checks.log") }
      yield root, environment, [RbConfig.ruby, File.join(scripts, "check.rb")]
    end
  end

  def test_check_fails_for_each_unsuccessful_gate_and_continues_running_checks
    with_check_fixture do |_root, environment, command|
      gates = %w[git test-bot bundle shellcheck zizmor pinprick lychee]
      [nil, *gates].each do |failed_gate|
        File.write(environment.fetch("CHECK_LOG"), "")
        _stdout, stderr, status = Open3.capture3(
          environment.merge("FAIL_CHECK" => failed_gate), *command, unsetenv_others: true
        )
        assert_equal failed_gate.nil?, status.success?, "#{failed_gate || "all successful"}: #{stderr}"
        assert_equal gates, File.readlines(environment.fetch("CHECK_LOG"), chomp: true)
      end
    end
  end

  def test_check_fails_for_invalid_ruby_and_missing_tools
    with_check_fixture do |root, environment, command|
      invalid_script = File.join(root, "scripts", "invalid.rb")
      File.write(invalid_script, "def\n")
      _stdout, stderr, status = Open3.capture3(environment, *command, unsetenv_others: true)
      refute status.success?, stderr
      assert_includes File.readlines(environment.fetch("CHECK_LOG"), chomp: true), "lychee"

      FileUtils.rm(invalid_script)
      FileUtils.rm(File.join(root, "bin", "shellcheck"))
      File.write(environment.fetch("CHECK_LOG"), "")
      _stdout, stderr, status = Open3.capture3(environment, *command, unsetenv_others: true)
      refute status.success?
      assert_includes stderr, "shellcheck: shellcheck not found"
      assert_includes File.readlines(environment.fetch("CHECK_LOG"), chomp: true), "lychee"
    end
  end
end
