cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.17.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz",
      verified: "github.com/starhaven-io/pinprick/"
  name "pinprick"
  desc "GitHub Actions supply chain security tool"
  homepage "https://pinprick.rs/"

  on_macos do
    sha256 "182843f304f7f390c493abd6460f71073ab4a38db2ef1077e288275701c26a45"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "46edd191f22f445a199099aa63a194c1ecb69de4f94cad69c169c7eba9607f85",
           x86_64_linux: "431dfa0009f5a91ade9d030866addcfa67c72505086b537cf7c336ec4566c264"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
