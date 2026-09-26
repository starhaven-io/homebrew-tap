cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.9.2"
  sha256 arm:          "d4286dc3e1dd3517f053a5aaba0865ed7c92c20cc5e082c2caa9bef1cc45d892",
         arm64_linux:  "d3a48bd6dbb25ba9e2adf409cc2a125d7cd1a00531d388e4015ea55845db1bc8",
         x86_64_linux: "ad82ed1ddb709bf753ae185bc5331ba4980eb453982bc22d60643978b6065e36"

  on_macos do
    depends_on arch: :arm64
  end

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Resolve, audit, visualize, and clean coding-agent context and state"
  homepage "https://github.com/starhaven-io/midden"

  binary "midden"
  generate_completions_from_executable "midden", "completions"
end
