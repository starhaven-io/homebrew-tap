cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.10.1"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "Pin your GitHub Actions. Prick holes in their supply chain security"
  homepage "https://github.com/starhaven-io/pinprick"

  on_macos do
    sha256 "7306f2a89b66f4dc148eccc046a356d9d0669707aa2d9ee64321e30c165c9360"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "335a1b8423a8e0ad6641239164d932c2ac15f329ba00ea3afba2e010f49d7406",
           x86_64_linux: "88558335f85ef7ded97f12caf16453309c3531da314e4d59b8870a8d74a8083d"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
