# typed: strict
# frozen_string_literal: true

require "json"

# Derives CI runners from validated cask source files.
module CaskMatrix
  TOKEN_PATTERN = /\A[a-z0-9][a-z0-9_.+-]*\z/
  MACOS_RUNNER = "macos-26"
  LINUX_RUNNER = "ubuntu-24.04"

  class InvalidCask < StandardError; end

  module_function

  def build(tokens, root: Dir.pwd)
    entries = tokens.uniq.flat_map do |token|
      validate_token!(token)
      path = File.join(root, "Casks", "#{token}.rb")
      validate_path!(path, token)

      runners = [MACOS_RUNNER]
      runners << LINUX_RUNNER if File.read(path, encoding: "UTF-8").match?(/^\s*on_linux\s+do\b/)
      runners.map { |runner| { cask: token, runner: runner } }
    end

    { include: entries }
  end

  def validate_token!(token)
    return if token.match?(TOKEN_PATTERN)

    raise InvalidCask, "invalid cask token: #{token}"
  end

  def validate_path!(path, token)
    stat = File.lstat(path)
    return if stat.file? && !stat.symlink?

    raise InvalidCask, "cask must be a regular file: #{token}"
  rescue Errno::ENOENT
    raise InvalidCask, "unknown cask token: #{token}"
  end
end

if $PROGRAM_NAME == __FILE__
  puts JSON.generate(CaskMatrix.build(ARGV))
end
