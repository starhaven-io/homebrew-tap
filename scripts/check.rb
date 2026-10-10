#!/usr/bin/env ruby
# typed: strict
# frozen_string_literal: true

require "rbconfig"

Dir.chdir(File.expand_path("..", __dir__))
$stdout.sync = true
failed = false
run = lambda do |label, *command|
  puts "--- #{label} ---"
  success = system(*command)
  unless success
    warn "#{label}: #{command.first} not found" if success.nil?
    failed = true
  end
end
run.call("diff", "git", "diff", "--check")
Dir["scripts/*.rb", "test/*.rb"].sort.each { |path| run.call("ruby-syntax #{path}", RbConfig.ruby, "-c", path) }
run.call("test-bot", RbConfig.ruby, "scripts/check_homebrew_syntax.rb", Dir.pwd,
         ENV.fetch("HOMEBREW_TAP_NAME", "starhaven-io/tap"))
run.call("tests", "bundle", "exec", "ruby", "-e",
         'Dir["test/*_test.rb"].sort.each { |file| require File.expand_path(file) }')
run.call("shellcheck", "shellcheck", *Dir[".githooks/*"])
run.call("zizmor", "zizmor", "--strict-collection", "--persona", "auditor", ".")
run.call("pinprick-audit", "pinprick", "audit", ".")
run.call("lychee", "lychee", "--config", "lychee.toml", "README.md")
exit(failed ? 1 : 0)
