cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.7.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "Pin your GitHub Actions. Prick holes in their supply chain security"
  homepage "https://github.com/starhaven-io/pinprick"

  on_macos do
    sha256 "1b82c4179c6deb7afe3f487fc01fc75ff76bd832363c187a15fa279e1a8a3dac"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "8d3298061aa261a78d08bbfa8b330be8d74ae240ccebd8d4342c0626d22aa6c9",
           x86_64_linux: "4f1c2f6e548ec2f2b6804fce466eda0083576b3ec7941a295584a2010786dcf2"
  end

  binary "pinprick"

  zap trash: "~/.config/pinprick"
end
