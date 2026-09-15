cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.25.1"
  sha256 arm:          "648efc40d12570e4bb8cdd9b7e14d3fce1adfd12aa6e97f761037b5e4355f3b7",
         arm64_linux:  "7c8b37cb11d960a39b939b296fa0da4a368a78990bf44d20241dc2c377139a78",
         x86_64_linux: "d2354dd53ae07c87c827a9afcf5872fd770bea9f9f866da13dab22f5476ad634"

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
