cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.21.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz",
      verified: "github.com/starhaven-io/pinprick/"
  name "pinprick"
  desc "GitHub Actions supply chain security tool"
  homepage "https://pinprick.rs/"

  on_macos do
    sha256 "954e76db223f726ea79f22a3d5747b82c8fcf77daebc204a8e1948a14b937ae7"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "239e6d2cc08696423fc211327c8b94f5074ad616ca51cb3b57a60ee9d4f447ca",
           x86_64_linux: "c9c86cdeaf0dbec4645781a5e0bc832e5ee52449d5946643dab3c175b2b3d5fd"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
