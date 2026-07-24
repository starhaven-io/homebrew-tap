cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.8.0"

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Resolve, audit, visualize, and clean coding-agent context and state"
  homepage "https://github.com/starhaven-io/midden"

  on_macos do
    sha256 "ecebb835597dbe0aa0a0ea5c375dd4faaa4fef6867f8bd9ad2450a32b05537e6"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "f210801f73be0904066276fbacaa4c675e0fcc0eafa95267c29150fafeca4292",
           x86_64_linux: "ff05952c1cafa2c51a4e2d536b599c8e001ba790b95da0ee09d2b29e8b8931ba"
  end

  binary "midden"

  generate_completions_from_executable "midden", "completions"
end
