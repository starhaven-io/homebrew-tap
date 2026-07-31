cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.8.1"

  on_macos do
    sha256 "e53ca0cf7a8d3f184fb6deb7e3bb4e51f1ce45e7f00bae7961940925752251cb"

    depends_on arch: :arm64
  end
  on_linux do
    sha256 arm64_linux:  "ad02ace8a1b8bcee12e1dd1985ee0f08cfc1c79bf93af04e0754f77437006527",
           x86_64_linux: "bea85913cc540378b00f089026ba42cdc262e26f16dc21a73c8c0aee080f8981"
  end

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Resolve, audit, visualize, and clean coding-agent context and state"
  homepage "https://github.com/starhaven-io/midden"

  binary "midden"
  generate_completions_from_executable "midden", "completions"
end
