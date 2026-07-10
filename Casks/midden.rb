cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.7.0"

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Resolve, audit, and garbage-collect Claude Code's accumulated state"
  homepage "https://github.com/starhaven-io/midden"

  on_macos do
    sha256 "690a9c12aaa60832d7a759bed9209fe6ed955394568da6a7ee64db1c3776886d"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "def0b17572377bc9f8e407caaca56487e800b8240635636f0cffc170aaea6644",
           x86_64_linux: "a181be14dc84f58e4d4b3adfafa3f558d4ad9d8212ed6fad4ea8d3648631c38f"
  end

  binary "midden"

  generate_completions_from_executable "midden", "completions"
end
