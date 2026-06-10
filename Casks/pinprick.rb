cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.12.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "Pin your GitHub Actions. Prick holes in their supply chain security"
  homepage "https://github.com/starhaven-io/pinprick"

  on_macos do
    sha256 "25c0194aa070f8072881ddc3e559f566dd00cf140e2325862d6acf780e1f2461"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "1bf54dcc6dfcad2c18ad065658b5dae41baf651d6ae875a06679b8086d7d9fc2",
           x86_64_linux: "e27b379df1374330e975ca9485427cff98b7ccbabce52d8f1fd172991cec941d"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
