cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.6.0"

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Resolve, audit, and garbage-collect Claude Code's accumulated state"
  homepage "https://github.com/starhaven-io/midden"

  on_macos do
    sha256 "37573b845b706ead1ee39ee93dc7f51fb71208c1739a522f80fbee80e90141bf"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "0b3f3a5ac298a540fde7f31fe538123157aed35de4132f2ce7b917a0e4e3e2c2",
           x86_64_linux: "55f54be0719208d5231d13f97f1e8b6c91b322e61f8290ddbf97e708430620bc"
  end

  binary "midden"

  generate_completions_from_executable "midden", "completions"
end
