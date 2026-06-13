cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.15.0"

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz"
  name "pinprick"
  desc "Pin your GitHub Actions. Prick holes in their supply chain security"
  homepage "https://github.com/starhaven-io/pinprick"

  on_macos do
    sha256 "71dbcd2e9c3a1790e95d4f6727a3beae0babd6aa7441082489d400e06b9adfb6"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "bcf35dee4430a95cac23b98805ab16a96667a8b7f0ddf60686fce702b12e0023",
           x86_64_linux: "c5d4e1deff6d022b9e84b1073f43f3924fcf1e1ca65c89864ee698af01409563"
  end

  binary "pinprick"

  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
