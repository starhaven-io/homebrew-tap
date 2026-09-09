cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.9.0"
  sha256 arm:          "d9c1710b72830e0f8a2715ae92bfc551ea2dfb19f9b296372c7f4bfa3fb60637",
         arm64_linux:  "2ac0f1c82462be6fe60a9be05cc0203f3f0fe396c635ce02a370f653b8a790dc",
         x86_64_linux: "d3cf23213f301c878f9626c5c3b7cee1b6f56098dab3a763915b3618b32169f5"

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
