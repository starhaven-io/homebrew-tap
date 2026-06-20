cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.16.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "Pin your GitHub Actions. Prick holes in their supply chain security"
  homepage "https://github.com/starhaven-io/pinprick"

  on_macos do
    sha256 "6f15bdfd281dd3b4b220e5cf75091e80ab73186671704bfb89c663e7784fda69"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "0261fcbd52174a04976daf4d9280d0bf468bff9f10fb780814985215898e7f3c",
           x86_64_linux: "dc3d7289c1b27a37431bd427622277c0b669f54fbefa7e2a4760830d6e94ae33"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
