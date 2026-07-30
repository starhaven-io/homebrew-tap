cask "pinprick" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.22.0"

  on_macos do
    sha256 "dc392bc7f906e75a2cbeba0b9da462e411abd393f53aaa8f27f18e2ff70ea810"

    depends_on arch: :arm64
  end
  on_linux do
    sha256 arm64_linux:  "c5e519babfd26eceb33ec446390a0bd2996dc55e471962c86549da061d61f8d0",
           x86_64_linux: "b95f600c6b61cdb0830e465f70b03a654f1bbe10f2211a55cb665e2a56b81b13"
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
