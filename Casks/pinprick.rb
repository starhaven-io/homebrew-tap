cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.11.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "Pin your GitHub Actions. Prick holes in their supply chain security"
  homepage "https://github.com/starhaven-io/pinprick"

  on_macos do
    sha256 "268b0a6682d7c8d2d99547449f583c72552aecfacbb4d405f8d47af2a80deaf7"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "1891c5135a4dc48ea589a8bbf6c0bc0fc41048c3be8c95096262ac6adb431611",
           x86_64_linux: "41bc354ccd33888ec62f6e32d98babbd0b96c9ee4b70d517a9e7a8e42cf69549"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
