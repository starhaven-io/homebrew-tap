cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.23.1"

  on_macos do
    sha256 "60699a1356438d1b4e66da9d5ffdedf5fdd0f74e033044cf2faf25518e07118b"

    depends_on arch: :arm64
  end
  on_linux do
    sha256 arm64_linux:  "2c8b1eedac453f23af79762719d442750b32859ebb3e463df4ab035aa844bbfb",
           x86_64_linux: "f3c4f51423c521c8b1f34588f3d2d228b0604497a9e4c09eab438acc12b558ee"
  end

  url "https://github.com/starhaven-io/pinprick/releases/download/v#{version}/pinprick-#{version}-#{arch}-#{os}.tar.gz",
      verified: "github.com/starhaven-io/pinprick/"
  name "pinprick"
  desc "GitHub Actions supply chain security tool"
  homepage "https://pinprick.rs/"

  binary "pinprick"
  generate_completions_from_executable "pinprick", "completions"

  zap trash: "~/.config/pinprick"
end
