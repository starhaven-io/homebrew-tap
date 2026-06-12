cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.13.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "Pin your GitHub Actions. Prick holes in their supply chain security"
  homepage "https://github.com/starhaven-io/pinprick"

  on_macos do
    sha256 "69699c50e0666511c143047edcd3786ca11cf2e6bf09a3bdfec96fe313efd741"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "705e316b80eaef22b951fb066096b0d1d9a847aab5554b707349607a06a795ec",
           x86_64_linux: "4be18fecb60e48496007e32bca78b2309090e612fdd1e6cb7c713d376337a971"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
