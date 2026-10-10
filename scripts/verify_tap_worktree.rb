#!/usr/bin/env ruby
# typed: strict
# frozen_string_literal: true

require_relative "tap_worktree"

begin
  checkout = ARGV[0].to_s
  checkout = Dir.pwd if checkout.empty?
  name = ARGV[1].to_s
  name = "starhaven-io/tap" if name.empty?
  puts TapWorktree.verify(checkout, name)
rescue TapWorktree::Error, SystemCallError => e
  warn e.message.lines.map { |line| "verify_tap_worktree: #{line}" }.join
  exit 1
end
