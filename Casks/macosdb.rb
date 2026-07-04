cask "macosdb" do
  version "2.2.0"
  sha256 "a9513bc6b6c16af4c0fdb71369976bff3dabbc27109ee9e71ff27d94a9d88c9e"

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
