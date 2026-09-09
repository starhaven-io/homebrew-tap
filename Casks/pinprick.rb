cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.24.1"
  sha256 arm:          "7acf1f84903fc07225aed832c643e091e9eb376f094f4b69cfc32ff7705906cc",
         arm64_linux:  "4c7729ae54d26a310da83f93e1e6ed2e63474d7e70e9be0f0026aa5a5769ed70",
         x86_64_linux: "b83f034f7240b6e6c64e30e96bad68fae61c3aaf8930dd4841bbf2431cb790b5"

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
