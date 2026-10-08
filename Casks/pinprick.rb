cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.29.0"
  sha256 arm:          "420c2c3a7e8afc34ddf5a86b30713ddee759edeeb89640f1f7a637e2b76b8094",
         arm64_linux:  "ad3f816de13af5ccd4847cf979eb16ae491f27791689c15bc7c9227ce5c2332f",
         x86_64_linux: "84ce70123899949ee453fde96e453ae7d64724258bf91eaaf30192cae7b3270a"

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
