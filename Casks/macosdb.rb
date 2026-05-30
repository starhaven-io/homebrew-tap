cask "macosdb" do
  version "1.13.1"
  sha256 "5f23e95370bf853e3885d56590f406aecc08f8062ff3ce5e1f7bc1c05ca8d123"

  url "https://github.com/starhaven-io/macOSdb/releases/download/#{version}/macOSdb-#{version}.zip"
  name "macOSdb"
  desc "Catalog of open-source components from .ipsw and .xip files"
  homepage "https://github.com/starhaven-io/macOSdb"

  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "macOSdb.app"
  binary "#{appdir}/macOSdb.app/Contents/MacOS/macosdb-tool", target: "macosdb"

  generate_completions_from_executable "#{appdir}/macOSdb.app/Contents/MacOS/macosdb-tool", "completions"

  zap trash: [
    "~/Library/Application Scripts/io.linnane.macOSdb",
    "~/Library/Caches/io.linnane.macosdb",
    "~/Library/Caches/macosdb",
    "~/Library/Caches/macOSdbApp",
    "~/Library/Containers/io.linnane.macOSdb",
    "~/Library/HTTPStorages/io.linnane.macosdb",
    "~/Library/HTTPStorages/macosdb",
    "~/Library/HTTPStorages/macOSdbApp",
    "~/Library/Preferences/io.linnane.macosdb.plist",
    "~/Library/Preferences/macOSdbApp.plist",
  ]
end
