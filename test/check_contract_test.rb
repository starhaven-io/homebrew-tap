# typed: strict
# frozen_string_literal: true

require "minitest/autorun"

class CheckContractTest < Minitest::Test
  JUSTFILE = File.expand_path("../justfile", __dir__).freeze

  def test_unlinked_homebrew_coverage_fails_the_aggregate_check
    recipe = File.read(JUSTFILE).match(/^check:\n(?<body>(?:    .*\n|\n)*)/)&.[](:body)

    refute_nil recipe
    assert_includes recipe, "run test-bot bash scripts/check_homebrew_syntax.sh"
    assert_includes recipe, "run zizmor zizmor --persona auditor ."
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
end
