cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.25.0"
  sha256 arm:          "81455881ea4484bf33a506b8e92e638bcbe289af4196fe01cca6dd2b6ba1d52c",
         arm64_linux:  "17ff4733f0d64e95bf011b043ef6c6d2c255dd808293eea30f21eafecd39cdc1",
         x86_64_linux: "8d64b6471536e0e3eee4a6f7be338bd2183aeb56593ad0b0da399db524f92277"

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
