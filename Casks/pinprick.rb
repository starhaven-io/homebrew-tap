cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.9.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "Pin your GitHub Actions. Prick holes in their supply chain security"
  homepage "https://github.com/starhaven-io/pinprick"

  on_macos do
    sha256 "bd8bea95ada472b4cb92edd49ae1d7836f60f200b669462250ceb4a5f42632a5"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "a62907a514a81d5f820a3b6df5a3c45d4422b5443a18ae1239beb91dec5b4cea",
           x86_64_linux: "940701ecc2f1cb63097bfb228fbc5b0a6ddecf1d91253685e3334d93ab7eab67"
  end

  binary "pinprick"

  zap trash: "~/.config/pinprick"
end
