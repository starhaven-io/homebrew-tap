# Casks

export HOMEBREW_DEVELOPER := "1"
export HOMEBREW_NO_AUTO_UPDATE := "1"
export HOMEBREW_NO_ENV_HINTS := "1"

tap_name := env_var_or_default("HOMEBREW_TAP_NAME", "starhaven-io/tap")

# Audit a cask by token
audit-cask token:
    #!/usr/bin/env bash
    set -euo pipefail
    token={{ quote(token) }}
    resolved_tap="$(ruby scripts/verify_tap_worktree.rb {{ quote(justfile_directory()) }} {{ quote(tap_name) }})"
    ruby scripts/cask_matrix.rb "${token}" > /dev/null
    brew audit --cask --online --strict "${resolved_tap}/${token}"

# Fetch every platform variation of a cask by token
fetch token:
    #!/usr/bin/env bash
    set -euo pipefail
    token={{ quote(token) }}
    resolved_tap="$(ruby scripts/verify_tap_worktree.rb {{ quote(justfile_directory()) }} {{ quote(tap_name) }})"
    ruby scripts/cask_matrix.rb "${token}" > /dev/null
    brew fetch --cask --retry --force --os=all --arch=all "${resolved_tap}/${token}"

# Run repository-wide Homebrew syntax checks
test-bot:
    ruby scripts/check_homebrew_syntax.rb {{ quote(justfile_directory()) }} {{ quote(tap_name) }}

# Test CI policy and cask platform routing
test:
    bundle exec ruby -e 'Dir["test/*_test.rb"].sort.each { |file| require File.expand_path(file) }'

# Lint shared Git hooks
shellcheck:
    shellcheck .githooks/*

# Audit GitHub Actions workflows with the repo zizmor policy
zizmor:
    zizmor --strict-collection --persona auditor .

# fleet:block pinprick-audit
pinprick-audit:
    pinprick audit .
# fleet:end

# Check README links
lychee:
    lychee --config lychee.toml README.md

# Check

# Run all checks
check:
    ruby scripts/check.rb

# Setup

# Install locked repository test dependencies
setup:
    bundle install

# Link this checkout under a private tap alias for token-based Homebrew checks.
link-tap alias="starhaven-worktree/tap":
    ruby scripts/link_tap_worktree.rb {{ quote(alias) }} {{ quote(justfile_directory()) }}

# fleet:block install-hooks
# Install git hooks (AI trailer guard + DCO sign-off + pre-push checks). Run once per clone.
install-hooks:
    git config core.hooksPath .githooks
# fleet:end

# fleet:block audit
audit:
    zizmor --strict-collection --persona auditor .github/workflows/
# fleet:end
