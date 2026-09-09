cask "macosdb" do
  version "2.4.1"
  sha256 "95b6a5bf219e6a0cc3e2b77252d8a23042ddb3d89fe5ec05d0fa8bca62298ede"

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
