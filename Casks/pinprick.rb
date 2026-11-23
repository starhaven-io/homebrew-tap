cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.35.0"
  sha256 arm:          "2de88d8f10f646a7f02ff5584bd67fab2c5973c517a69ff5d3dd851fc7b5047e",
         arm64_linux:  "166a95cb1a8a8bba029500e70b435e91b41f226ae4460d41cf73005286a750f8",
         x86_64_linux: "8fb3679e26e39ded9863a014c6e16129b6153bd9fac0f3e8f38ba3ed234d4130"

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
