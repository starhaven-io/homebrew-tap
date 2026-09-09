cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.9.1"
  sha256 arm:          "2ad7b362d04410ac5d659b60ed2d152aa0c345da98e35f3f57c2ab8cba0e6422",
         arm64_linux:  "f2f8dd8ea43eea6b76d8746779616cd52e685c2f3aa8f14fda85be41f9040bf4",
         x86_64_linux: "edbbfb456c2f3307c66bffe5bbdfd861a505c3da427961fb785e5b270a6511d1"

  on_macos do
    depends_on arch: :arm64
  end

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Resolve, audit, visualize, and clean coding-agent context and state"
  homepage "https://github.com/starhaven-io/midden"

  binary "midden"
  generate_completions_from_executable "midden", "completions"
end
