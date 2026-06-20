cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.4.0"

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Audit Claude Code's config sprawl. Clean up the midden left behind"
  homepage "https://github.com/starhaven-io/midden"

  on_macos do
    sha256 "1fd52de2505aceacb53b4a8117f93e802ac63b4611fb2831d0ed314b675dc98e"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "e4f126ce35899b163333c81bd5241ee67c52570f932c6231568e35af273f137b",
           x86_64_linux: "81aca6d78a5eb21b2c36548f8ec8efc0e1cd28314a5486700df0387b7a9a9162"
  end

  binary "midden"

  generate_completions_from_executable "midden", "completions"
end
