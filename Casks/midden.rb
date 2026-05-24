cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.1.1"

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Resolve, audit, and garbage-collect Claude Code's accumulated state"
  homepage "https://github.com/starhaven-io/midden"

  on_macos do
    sha256 "348c0b2275811fa6a4faecbe56617ade0688c4508852ea1d1395ef6da6fc6281"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "73c65c2e971ce9373f1a4e70a8c95469a397c91623cc6c575108e492ef351418",
           x86_64_linux: "3d95b9c62d603b60a2286c17bf073d99500b8c7fb88a7baf8c23ff16c4ee1883"
  end

  binary "midden"

  zap trash: "~/.config/midden"
end
