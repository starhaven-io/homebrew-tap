cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.20.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz",
      verified: "github.com/starhaven-io/pinprick/"
  name "pinprick"
  desc "GitHub Actions supply chain security tool"
  homepage "https://pinprick.rs/"

  on_macos do
    sha256 "fe69c86521cbe4e90e270276606c162bdf39d6160fa4756712c15b7ab6832eba"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "52418c0e5c3bd4506414210a9560d90ce51b60ef9d902361cb7c2a0bfd29782d",
           x86_64_linux: "0c7fde7c0725c85fbb38d119d849551e626a2dcb6ebd3eeb6695296f47d204d5"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
