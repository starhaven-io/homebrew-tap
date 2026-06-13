cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.3.0"

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Audit Claude Code's config sprawl. Clean up the midden left behind"
  homepage "https://github.com/starhaven-io/midden"

  on_macos do
    sha256 "a95bbb1f8b99a6a1c0aab0d7525427c13bda820cad5c470c3c9073f34c6642c0"

    depends_on arch: :arm64
  end

  on_linux do
    sha256 arm64_linux:  "46b90b7f4e167b47ff43968a99bb1548f37d71138764b23b780b239de4fa0887",
           x86_64_linux: "4134a58dd1be85a18bf03d7e395d698b243127dd48dbeec775eb20e535971554"
  end

  binary "midden"

  generate_completions_from_executable "midden", "completions"
end
