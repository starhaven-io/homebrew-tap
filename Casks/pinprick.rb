cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.24.2"
  sha256 arm:          "072be338305e165fa2ad6ed951fbe4e4462d1c8beaed65e029be99d320595b64",
         arm64_linux:  "f9d1d097ac41b2bf4690bc3fa286a4421e541c2da332c51dfd18de1a5d78bf8d",
         x86_64_linux: "6f37ca082c6d6f4e0b6179f2524517a94f816b2854d01a551b9958f88ccdb7ff"

  on_macos do
    depends_on arch: :arm64
  end

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "GitHub Actions supply chain security tool"
  homepage "https://pinprick.rs/"

  binary "pinprick"
  generate_completions_from_executable "pinprick", "completions"

  zap trash: [
    "~/.cache/pinprick",
    "~/.config/pinprick",
  ]
end
