cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.26.0"
  sha256 arm:          "b552fe485c01dd9dadc0da4e8d3ab86b9648d071302136e6fc5a43d8c13692f6",
         arm64_linux:  "40492ca4eaf6598536c582992e7800b3400ace0f9584bd25f2b989c1723d1e42",
         x86_64_linux: "d1a316833c4e9b5eabfd535ed2cb90db78738050e3b452ecb097ca34612ca55c"

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
