#!/usr/bin/env ruby
# typed: strict
# frozen_string_literal: true

require_relative "tap_worktree"

begin
  name = ARGV[0].to_s
  name = "starhaven-worktree/tap" if name.empty?
  checkout = ARGV[1].to_s
  checkout = Dir.pwd if checkout.empty?
  checkout = TapWorktree.link(name, checkout)
  puts "Linked #{name} to #{checkout}"
  puts "Run: HOMEBREW_TAP_NAME=#{name} just check"
rescue TapWorktree::Error, SystemCallError => e
  warn "link_tap_worktree: #{e.message}"
  exit 1
end
