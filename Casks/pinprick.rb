cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.20.1"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz",
      verified: "github.com/starhaven-io/pinprick/"
  name "pinprick"
  desc "GitHub Actions supply chain security tool"
  homepage "https://pinprick.rs/"

  on_macos do
    sha256 "9ac8f723f7f15c2ab1228f0a281aea6a94912a9fd80e09bbaa7fe51b5a38356c"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "2b7ad70c2cc897508718712bfe5b6dedd436733d9d09d7d571f8e8616aeac81d",
           x86_64_linux: "215dbd542ad06873527b2dfc53a373a0ed57055375d5bd6500f64b0d7e818fed"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
