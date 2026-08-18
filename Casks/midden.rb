cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.8.2"

  on_macos do
    sha256 "4fd7d11ee68234869206f3a9b9f18a05b22aa005d8dd59da1157930fef3e8f1f"

    depends_on arch: :arm64
  end
  on_linux do
    sha256 arm64_linux:  "36a182619815892aaf8984d4cc01005ee88af9a8ac1df68753b72c891a74ad40",
           x86_64_linux: "fcc8c738c9ffc6636329970c2905fd1ed647b19a29335e02516619704fc35133"
  end

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Resolve, audit, visualize, and clean coding-agent context and state"
  homepage "https://github.com/starhaven-io/midden"

  binary "midden"
  generate_completions_from_executable "midden", "completions"
end
