cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.24.0"
  sha256 arm:          "8fa50ec62422ab78af544dfda66b2199015979a9994b2e407034c0bc48889194",
         arm64_linux:  "2bf15346933f096a6539169d634b0c2f36a4ce9f286bb4878a20153e0ea48969",
         x86_64_linux: "a869f87a06aadc16b96d73a2aa5965a5cfbdd24f6b7905eca6ea1e9b2ca0b1b7"

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
