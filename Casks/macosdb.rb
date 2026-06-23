cask "macosdb" do
  version "2.1.1"
  sha256 "efa292358bdf60a14b6eca101a3516dbabdf3603a482c15c048d0e1e2fd0e65f"

  url "https://github.com/starhaven-io/macOSdb/releases/download/#{version}/macosdb-#{version}-aarch64-apple-darwin.tar.gz",
      verified: "github.com/starhaven-io/macOSdb/"
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
