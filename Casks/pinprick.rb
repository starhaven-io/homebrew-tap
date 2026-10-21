cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.32.0"
  sha256 arm:          "e2e4d49263cfce8278dfd61e8e994249b65587445f6feac8673225664bffbc05",
         arm64_linux:  "7a2cc65675ba498bf01d09a813585ec411be2b4a2512cdc72a85309483f6eb36",
         x86_64_linux: "64404ce558cc9cdde852d9716da3fc8c5812a7aefadd5b5ffe3087ffac49f1ba"

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
