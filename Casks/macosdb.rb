cask "macosdb" do
  version "1.13.0"
  sha256 "b662178de8d5ac69b80e55b045d1b071ec7fa429d441f0dab194552193eed72e"

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
