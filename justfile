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
    resolved_tap="$(bash scripts/verify_tap_worktree.sh {{ quote(justfile_directory()) }} {{ quote(tap_name) }})"
    ruby scripts/cask_matrix.rb "${token}" > /dev/null
    brew audit --cask --online --strict "${resolved_tap}/${token}"

# Fetch a cask by token
fetch token:
    #!/usr/bin/env bash
    set -euo pipefail
    token={{ quote(token) }}
    resolved_tap="$(bash scripts/verify_tap_worktree.sh {{ quote(justfile_directory()) }} {{ quote(tap_name) }})"
    ruby scripts/cask_matrix.rb "${token}" > /dev/null
    brew fetch --cask --retry --force "${resolved_tap}/${token}"

# Run repository-wide Homebrew syntax checks
test-bot:
    #!/usr/bin/env bash
    set -euo pipefail
    resolved_tap="$(bash scripts/verify_tap_worktree.sh {{ quote(justfile_directory()) }} {{ quote(tap_name) }})"
    brew test-bot --tap "${resolved_tap}" --only-tap-syntax

# Test CI policy and cask platform routing
test:
    ruby -e 'Dir["test/*_test.rb"].sort.each { |file| require File.expand_path(file) }'

# Lint GitHub Actions workflows
actionlint:
    actionlint

# Lint repository shell scripts
shellcheck:
    shellcheck scripts/*.sh

# Audit GitHub Actions workflows with the repo zizmor policy
zizmor:
    zizmor --persona auditor .

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
    #!/usr/bin/env bash
    set -euo pipefail
    failed=0
    skipped=()
    run() {
        echo "--- $1 ---"
        shift
        if ! "$@"; then
            failed=1
        fi
    }
    skip() {
        echo "--- $1 --- skipped ($2 not found)"
        skipped+=("$2 (brew install $3)")
    }
    run test-bot bash scripts/check_homebrew_syntax.sh {{ quote(justfile_directory()) }} {{ quote(tap_name) }}
    run tests ruby -e 'Dir["test/*_test.rb"].sort.each { |file| require File.expand_path(file) }'
    if command -v actionlint &>/dev/null; then
        run actionlint actionlint
    else
        skip actionlint actionlint actionlint
    fi
    if command -v shellcheck &>/dev/null; then
        run shellcheck shellcheck scripts/*.sh
    else
        skip shellcheck shellcheck shellcheck
    fi
    if command -v zizmor &>/dev/null; then
        run zizmor zizmor --persona auditor .
    else
        skip zizmor zizmor zizmor
    fi
    if command -v pinprick &>/dev/null; then
        run pinprick-audit pinprick audit .
    else
        skip pinprick-audit pinprick pinprick
    fi
    if command -v lychee &>/dev/null; then
        run lychee lychee --config lychee.toml README.md
    else
        skip lychee lychee lychee
    fi
    if [ ${#skipped[@]} -gt 0 ]; then
        echo ""
        echo "Checks skipped due to missing tools:"
        for tool in "${skipped[@]}"; do
            echo "  - $tool"
        done
        failed=1
    fi
    exit "$failed"

# Setup

# Link this checkout under a private tap alias for token-based Homebrew checks.
link-tap alias="starhaven-worktree/tap":
    bash scripts/link_tap_worktree.sh {{ quote(alias) }} {{ quote(justfile_directory()) }}

# fleet:block install-hooks
# Install git hooks (AI trailer guard + DCO sign-off + pre-push checks). Run once per clone.
install-hooks:
    git config core.hooksPath .githooks
# fleet:end

# fleet:block audit
audit:
    zizmor --persona auditor .github/workflows/
# fleet:end
