cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.10.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "Pin your GitHub Actions. Prick holes in their supply chain security"
  homepage "https://github.com/starhaven-io/pinprick"

  on_macos do
    sha256 "eba75f9344c482eef6f216d91e8cc27078e3826bcaafcb0cd49c1ca7384357c2"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "337e054911b51cef53d92acf54c24d768611ab6bc5935b6d4e52a14694f103da",
           x86_64_linux: "09bb75708b8f79e436527a20ddd8bc4bb036da54386379547a28770c359aeae8"
  end

  binary "pinprick"

  zap trash: "~/.config/pinprick"
end
