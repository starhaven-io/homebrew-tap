#!/usr/bin/env bash
set -euo pipefail

checkout="${1:?checkout path is required}"
tap_name="${2:?tap name is required}"

if ! command -v brew >/dev/null 2>&1
then
  echo "check_homebrew_syntax: brew not found" >&2
  exit 1
fi

if ! resolved_tap="$(bash "${checkout}/scripts/verify_tap_worktree.sh" "${checkout}" "${tap_name}")"
then
  echo "check_homebrew_syntax: Homebrew is not linked to this checkout" >&2
  echo "check_homebrew_syntax: run 'just link-tap' before retrying" >&2
  exit 1
fi

brew test-bot --tap "${resolved_tap}" --only-tap-syntax
