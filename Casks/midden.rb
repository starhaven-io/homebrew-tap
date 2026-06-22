cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.5.0"

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Resolve, audit, and garbage-collect Claude Code's accumulated state"
  homepage "https://github.com/starhaven-io/midden"

  on_macos do
    sha256 "94088eec22a4e296cc1702d53a20f618bbaf7d97cdaef208c8f18b2564db8d9b"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "288d1276cb1bfe864ca39c3014921aa429c6e17b87ff83292a00a2bd59454306",
           x86_64_linux: "81b86a5bac8e8c8bc38ace4465e710f0287b898d75d66fdea7385d7dc5c67c88"
  end

  binary "midden"

  generate_completions_from_executable "midden", "completions"
end
