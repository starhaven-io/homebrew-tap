cask "midden" do
  arch arm: "aarch64", intel: "x86_64"
  os macos: "apple-darwin", linux: "unknown-linux-gnu"

  version "0.9.3"
  sha256 arm:          "0c553d099a79337726b0bcb17fde73d523a737f48732a7fe005724e1dfdbfc26",
         arm64_linux:  "db1950e56fc665250e358ae6975e6574c1c7685de52c648ee6335e5ed639d1f7",
         x86_64_linux: "491c7b873019a47f2c11853ad63c52bcc700b386d517e0ccc5ffc2342e70d6b3"

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
