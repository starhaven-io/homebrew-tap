cask "macosdb" do
  version "2.1.2"
  sha256 "6b322b82e206603ac5db9a4dd9663da2847f5c9e39b326b835b678f0caa9bcfd"

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
