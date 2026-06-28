cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.19.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz",
      verified: "github.com/starhaven-io/pinprick/"
  name "pinprick"
  desc "GitHub Actions supply chain security tool"
  homepage "https://pinprick.rs/"

  on_macos do
    sha256 "e46fa94d5b53fbaa4faeab64d51d29bdc7ba63127bee6f553f7aecbe2c814b6e"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "ffb99c1c1c80e327590ce081f87aed438cc484ad84d7e6a5f52e9616e28d1ebc",
           x86_64_linux: "7fe17b35be2410fae3a80e08862029e1b95b221d5ad564c041496b8a5fd38c98"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
