cask "macosdb" do
  version "2.3.0"
  sha256 "4a562f3b6a6e97312dbacf50aba6e58bf3c55fcd649a32eac2df139cfcdb76a0"

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
