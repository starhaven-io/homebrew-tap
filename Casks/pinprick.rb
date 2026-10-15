cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.30.0"
  sha256 arm:          "06cd6e16a71d41a8c61d7bebf67975c7aa291d982886c6424adc46da451b0d5f",
         arm64_linux:  "cbb656e37bdfbd01a752bdc1d3174ca935bcdf30ab1aeb0483acc4dc36fae340",
         x86_64_linux: "d967410ec3e7f7da73c1a7a1bfef669ae4a7916bea46b80ffc3972759a6e8d23"

  on_macos do
    depends_on arch: :arm64
  end

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "GitHub Actions supply chain security tool"
  homepage "https://pinprick.rs/"

  binary "pinprick"
  generate_completions_from_executable "pinprick", "completions"

  zap trash: [
    "~/.cache/pinprick",
    "~/.config/pinprick",
  ]
end
