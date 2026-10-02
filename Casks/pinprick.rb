cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.28.0"
  sha256 arm:          "da88867e3c183aa5d20525a57ab4eefd93413ffb4675dad311116310f8161a9c",
         arm64_linux:  "5a3c6f3026cad4ec40c3b76651dce4073ca6a65b6fd1b3e574787833d8208a37",
         x86_64_linux: "2db4b243d6fcfe14a99c5e2feca4ceceefb6d7cf5385b87634503fbd03592491"

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
