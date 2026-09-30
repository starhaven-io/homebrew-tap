cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.27.0"
  sha256 arm:          "a3d93ba6c8930f6ef053e62192cc720bee8e2d68c3f5fb6a7ae5cba686c2f4a1",
         arm64_linux:  "9c1ac9f1b395ccaa8b87aacc46837af1ead6c67e087014fb814347c2bcc31263",
         x86_64_linux: "a0511a109caf98a47e25c4ea37545bec8c1415faa3fe8bf0d3a5bbbf5e167761"

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
