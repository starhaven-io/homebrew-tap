# typed: strict
# frozen_string_literal: true

require "fileutils"
require "open3"

# Binds token-based checks to this checkout without replacing existing taps.
# Binary paths prevent Ruby from transcoding filesystem arguments under legacy locales.
module TapWorktree
  class Error < StandardError; end

  NAME = %r{\A[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*\z}

  def self.validate_name!(name)
    raise Error, "invalid tap name: #{name}" unless NAME.match?(name)
  end

  def self.directory(path)
    path = path.b
    raise Error, "directory does not exist: #{path}" unless File.directory?(path)

    File.realpath(path).b
  end

  def self.brew(*arguments)
    output, status = Open3.capture2("brew", *arguments, binmode: true, err: File::NULL)
    raise Error, "brew #{arguments.join(" ")} failed" unless status.success?

    output.sub(/\n+\z/, "")
  rescue Errno::ENOENT
    raise Error, "brew not found"
  end

  def self.verify(checkout, name)
    validate_name!(name)
    expected_path = directory(checkout)
    requested_path = nil
    begin
      tap_path = brew("--repo", name)
      requested_path = directory(tap_path) if File.directory?(tap_path)
    rescue Error => e
      raise if e.message == "brew not found"
    end
    return name if requested_path == expected_path

    taps_root = File.join(brew("--repository"), "Library/Taps")
    matches = Dir.glob("*/homebrew-*", base: taps_root).filter_map do |relative|
      candidate = File.join(taps_root, relative.b)
      next if !File.symlink?(candidate) || !File.directory?(candidate)
      next if directory(candidate) != expected_path

      owner = File.basename(File.dirname(candidate))
      repository = File.basename(candidate).delete_prefix("homebrew-")
      candidate_name = "#{owner}/#{repository}"
      candidate_name if owner != "starhaven-io" && NAME.match?(candidate_name)
    end
    return matches.first if matches.one?

    lines = [requested_path ? "#{name} resolves to #{requested_path}" : "#{name} is not installed",
             "expected the checkout under test at #{expected_path}"]
    if matches.size > 1
      lines << "multiple private tap aliases resolve to this checkout:"
      lines.concat(matches.map { |match| "  - #{match}" })
      lines << "select one with HOMEBREW_TAP_NAME"
    else
      lines << "run 'just link-tap' before retrying"
    end
    raise Error, lines.join("\n")
  end

  def self.link(name, checkout)
    checkout = checkout.b
    validate_name!(name)
    raise Error, "checkout does not exist: #{checkout}" unless File.directory?(checkout)

    owner, repository = name.split("/")
    raise Error, "refusing to claim the canonical starhaven-io owner" if owner == "starhaven-io"

    checkout = directory(checkout)
    taps_root = File.join(brew("--repository"), "Library/Taps")
    FileUtils.mkdir_p(taps_root)
    owner_path = File.join(directory(taps_root), owner)
    raise Error, "refusing symlinked tap owner path: #{owner_path}" if File.symlink?(owner_path)
    if File.exist?(owner_path) && !File.directory?(owner_path)
      raise Error, "tap owner path is not a directory: #{owner_path}"
    end

    FileUtils.mkdir_p(owner_path)
    raise Error, "tap owner path escaped its namespace: #{owner_path}" if directory(owner_path) != owner_path

    tap_path = File.join(owner_path, "homebrew-#{repository}")
    if File.symlink?(tap_path)
      linked_path = directory(tap_path)
      raise Error, "#{tap_path} already links to #{linked_path}" if linked_path != checkout
    elsif File.exist?(tap_path)
      raise Error, "refusing to replace existing path: #{tap_path}"
    else
      File.symlink(checkout, tap_path)
    end
    checkout
  end
end
