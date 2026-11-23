cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.9.4"
  sha256 arm:          "3f926ae738d443fcc44dc0271e4df0a4991f0ebd53a046b649e821f3d87b3fed",
         arm64_linux:  "b0af5d29e7cecbafd22cb976abcfc9640a3fe36640c9504713de7ef5d09ddd3a",
         x86_64_linux: "29d36f46325fd9974fb9e4a5e4a1abf8a8f29e26e9b7649c69be3273828cbc34"

  on_macos do
    depends_on arch: :arm64
  end

  url "https://github.com/starhaven-io/midden/releases/download/v#{version}/midden-#{version}-#{arch}-#{os}.tar.gz"
  name "midden"
  desc "Resolve, audit, visualize, and clean coding-agent context and state"
  homepage "https://github.com/starhaven-io/midden"

  binary "midden"
  generate_completions_from_executable "midden", "completions"
end
