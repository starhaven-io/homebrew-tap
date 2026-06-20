cask "macosdb" do
  version "2.0.1"
  sha256 "4bcc7db057159761f20f1546d8439b0b026f14f98f30a122cff8aedf3aaaf05d"

  url "https://github.com/starhaven-io/macOSdb/releases/download/#{version}/macosdb-#{version}-aarch64-apple-darwin.tar.gz"
  name "macOSdb"
  desc "Catalog of open-source components from .ipsw and .xip files"
  homepage "https://github.com/starhaven-io/macOSdb"

  depends_on arch: :arm64
  depends_on macos: :sequoia

  binary "macosdb"

  generate_completions_from_executable "macosdb", "completions"

  zap trash: [
    "~/Library/Caches/macosdb",
    "~/Library/HTTPStorages/macosdb",
  ]
end
