cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.18.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz",
      verified: "github.com/starhaven-io/pinprick/"
  name "pinprick"
  desc "GitHub Actions supply chain security tool"
  homepage "https://pinprick.rs/"

  on_macos do
    sha256 "8fa10de34b7ff5fff55ddab640b604741266108beb15212d6c4094536a076003"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "a4d008991ad00cd13b362ea25e8ff51777f4c833d4b944c0c58d4cd4c60cb522",
           x86_64_linux: "ce68048db722cec6d511a314f396ee4b3aa7fe8ac98b794817d2e9f31d16a6fb"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
