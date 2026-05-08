cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.8.1"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "Pin your GitHub Actions. Prick holes in their supply chain security"
  homepage "https://github.com/starhaven-io/pinprick"

  on_macos do
    sha256 "65a1ee1a619d6622d2bb80caf0ecee651430996f24b7c05259e9e997b39f5e73"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "1b676de467ac5808e63deb0f2b1b78fb370a632218dea9e8f99c1cb6420460db",
           x86_64_linux: "0f8a735c2d74f5aec113d8cfbdfaa93b09ae99145330822b7eaa6ef17bc7e5e0"
  end

  binary "pinprick"

  zap trash: "~/.config/pinprick"
end
