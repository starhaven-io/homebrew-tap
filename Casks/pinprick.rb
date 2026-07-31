cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.23.0"

  on_macos do
    sha256 "b1d345c2d675bd808f6c0d23d90ca02ac88ce22b86cc45d31c4a6d69951a5450"

    depends_on arch: :arm64
  end
  on_linux do
    sha256 arm64_linux:  "8df94c7c04f67405c20ab012551a3a8c02d4cdac2b4d46c47659cf0eba7735f4",
           x86_64_linux: "f47f75ff80f036ba2bb25a218f23293243ae7e39149e2f36171738f90b906e4f"
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
