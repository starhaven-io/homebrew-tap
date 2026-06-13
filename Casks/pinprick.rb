cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.14.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "Pin your GitHub Actions. Prick holes in their supply chain security"
  homepage "https://github.com/starhaven-io/pinprick"

  on_macos do
    sha256 "73a6586dc0b4140c48097d0022316e562c6da7b653eaa7d779038554d9d083d9"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "8b58c33fec627a486f2f3c7445756f4a8b40dcc99a031f375363ee9f6c97c926",
           x86_64_linux: "f54a4f84e6949a79272c8411977a19b257968155f954f5f343ac6e71d8338346"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
