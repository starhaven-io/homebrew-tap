cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.33.0"
  sha256 arm:          "56982c3220901b8fb43485fab0d9283e7809cb557d509dfe506b02b71cf0323c",
         arm64_linux:  "84e429f5dc4c4441b8b8fa531afb50a515a3071d1b4653c236f6c151660ef93f",
         x86_64_linux: "c16c1d01dbecdee8b84ebc7232ecbc499a2763093157911310b14c63e5b76dac"

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
