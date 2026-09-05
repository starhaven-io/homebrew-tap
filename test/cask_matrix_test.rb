# typed: strict
# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "tmpdir"

require_relative "../scripts/cask_matrix"

class CaskMatrixTest < Minitest::Test
  REPOSITORY_ROOT = File.expand_path("..", __dir__).freeze

  # This inventory assertion intentionally makes every cask addition, removal,
  # and platform change update the CI routing contract in review.
  def test_current_casks_map_to_supported_runners
    tokens = Dir[File.join(REPOSITORY_ROOT, "Casks/*.rb")].map { |path| File.basename(path, ".rb") }.sort
    matrix = CaskMatrix.build(tokens, root: REPOSITORY_ROOT)

    assert_equal(
      {
        include: [
          { cask: "brewy", runner: "macos-26" },
          { cask: "macosdb", runner: "macos-26" },
          { cask: "midden", runner: "macos-26" },
          { cask: "midden", runner: "ubuntu-24.04" },
          { cask: "pinprick", runner: "macos-26" },
          { cask: "pinprick", runner: "ubuntu-24.04" },
        ],
      },
      matrix,
    )
  end

  def test_linux_runner_is_derived_from_cask_source
    Dir.mktmpdir("cask-matrix-") do |root|
      FileUtils.mkdir_p(File.join(root, "Casks"))
      File.write(File.join(root, "Casks", "example.rb"), "cask \"example\" do\n  on_linux do\n  end\nend\n")

      assert_equal(
        {
          include: [
            { cask: "example", runner: "macos-26" },
            { cask: "example", runner: "ubuntu-24.04" },
          ],
        },
        CaskMatrix.build(["example"], root: root),
      )
    end
  end

  def test_invalid_and_unknown_tokens_fail_closed
    error = assert_raises(CaskMatrix::InvalidCask) do
      CaskMatrix.build(["../outside"], root: REPOSITORY_ROOT)
    end
    assert_includes error.message, "invalid cask token"

    error = assert_raises(CaskMatrix::InvalidCask) do
      CaskMatrix.build(["unknown"], root: REPOSITORY_ROOT)
    end
    assert_includes error.message, "unknown cask token"
  end

  def test_symlinked_cask_source_fails_closed
    Dir.mktmpdir("cask-matrix-") do |root|
      cask_directory = File.join(root, "Casks")
      FileUtils.mkdir_p(cask_directory)
      target = File.join(root, "outside.rb")
      File.write(target, "cask \"example\" do\nend\n")
      File.symlink(target, File.join(cask_directory, "example.rb"))

      error = assert_raises(CaskMatrix::InvalidCask) do
        CaskMatrix.build(["example"], root: root)
      end
      assert_includes error.message, "regular file"
    end
  end
end
