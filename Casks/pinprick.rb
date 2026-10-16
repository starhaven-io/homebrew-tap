cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.31.0"
  sha256 arm:          "a0c2491773285ec77b00a035806c432b335a94c9625528dd6b0c571b55ef1f8f",
         arm64_linux:  "7e73f8717ed22519cd5adb13864385be30bdd279a76f17b25b6bca3321231dab",
         x86_64_linux: "b5182c4618ecf7bf1e77fca5ba105b06f1799c3c63456046c58bfce73e4e16fb"

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
