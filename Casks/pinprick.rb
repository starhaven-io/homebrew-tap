cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.8.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "Pin your GitHub Actions. Prick holes in their supply chain security"
  homepage "https://github.com/starhaven-io/pinprick"

  on_macos do
    sha256 "10b1495927d42966ba6b0808c8f783ad63df415a80f494d1c41d754d20fb4baf"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "71d5910db4368a349332f2c14763554c7c83e1ded219524bf39329947c6259c1",
           x86_64_linux: "603f6d1ddc3aba23f898660103eac7fa9650b8560397bcbdeb9f060edcbc0e12"
  end

  binary "pinprick"

  zap trash: "~/.config/pinprick"
end
