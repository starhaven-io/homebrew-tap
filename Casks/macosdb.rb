cask "macosdb" do
  version "2.4.2"
  sha256 "eedc416ebd92ef4f842b5796ce3d0fb227ea7a1e460255793a0ff2b89b141a0a"

  url "https://github.com/starhaven-io/macOSdb/releases/download/#{version}/macosdb-#{version}-aarch64-apple-darwin.tar.gz"
  name "macOSdb"
  desc "Catalog of open-source components from .ipsw and .xip files"
  homepage "https://macosdb.com/"

  depends_on arch: :arm64
  depends_on macos: :sequoia

  binary "macosdb"
  generate_completions_from_executable "macosdb", "completions"

  zap trash: [
    "~/Library/Caches/macosdb",
    "~/Library/HTTPStorages/macosdb",
  ]
end
