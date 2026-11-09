cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.34.0"
  sha256 arm:          "17b5123884a6c3b1ed27ed0c23a8ae37ed5790cd262e2d396c4918e7fc87314f",
         arm64_linux:  "8f81070e9aeaa7826765f3293680d46e8779c50323846a8434917cfbe9b96954",
         x86_64_linux: "7d94ee1e29e0cd77f34362435b90d6a4c0d71336653c481eae6eed48ab684ae8"

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
