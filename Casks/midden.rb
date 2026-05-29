cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.2.0"

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Audit Claude Code's config sprawl. Clean up the midden left behind"
  homepage "https://github.com/starhaven-io/midden"

  on_macos do
    sha256 "feed9ca281ff31225da40dc1582c24a7823c1d3b5e8ef1e973589a82ba4b8782"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "a77f043a7bda88e9ee6d75ffeaa33ccce49e03ac3ce4f863c17fb69204eabd28",
           x86_64_linux: "2dd00daa96cf95b33c565a52a31643e3c3ac8cc239cc07bbdbd567678f79bdb0"
  end

  binary "midden"

  generate_completions_from_executable "midden", "completions"
end
