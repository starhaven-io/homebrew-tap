#!/usr/bin/env ruby
# typed: strict
# frozen_string_literal: true

require_relative "tap_worktree"

arguments = ARGV.first(2)
abort "usage: check_homebrew_syntax.rb CHECKOUT TAP_NAME" if arguments.length != 2 || arguments.any?(&:empty?)
begin
  resolved_tap = TapWorktree.verify(*arguments)
rescue TapWorktree::Error, SystemCallError => e
  warn "check_homebrew_syntax: #{e.message}"
  warn "check_homebrew_syntax: Homebrew is not linked to this checkout"
  warn "check_homebrew_syntax: run 'just link-tap' before retrying"
  exit 1
end
exec "brew", "test-bot", "--tap", resolved_tap, "--only-tap-syntax"
