#!/usr/bin/env bash
set -euo pipefail

expected_path="${1:-${PWD}}"
tap_name="${2:-starhaven-io/tap}"
if [[ ! "${tap_name}" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]]
then
  echo "verify_tap_worktree: invalid tap name: ${tap_name}" >&2
  exit 1
fi
if ! command -v brew >/dev/null 2>&1
then
  echo "verify_tap_worktree: brew not found" >&2
  exit 1
fi

canonicalize_directory() {
  local path="$1"
  if [[ ! -d "${path}" ]]
  then
    echo "verify_tap_worktree: directory does not exist: ${path}" >&2
    return 1
  fi
  (cd "${path}" && pwd -P)
}

expected_path="$(canonicalize_directory "${expected_path}")"
requested_path=""
if tap_path="$(brew --repo "${tap_name}" 2>/dev/null)" && [[ -d "${tap_path}" ]]
then
  requested_path="$(canonicalize_directory "${tap_path}")"
  if [[ "${requested_path}" == "${expected_path}" ]]
  then
    printf '%s\n' "${tap_name}"
    exit 0
  fi
fi

brew_repository="$(brew --repository)"
taps_root="${brew_repository}/Library/Taps"
matches=()
shopt -s nullglob
for candidate in "${taps_root}"/*/homebrew-*
do
  [[ -L "${candidate}" ]] || continue
  [[ -d "${candidate}" ]] || continue
  candidate_path="$(canonicalize_directory "${candidate}")"
  [[ "${candidate_path}" == "${expected_path}" ]] || continue

  relative_path="${candidate#"${taps_root}/"}"
  owner="${relative_path%%/*}"
  repository="${relative_path##*/homebrew-}"
  candidate_name="${owner}/${repository}"
  [[ "${owner}" != "starhaven-io" ]] || continue
  [[ "${candidate_name}" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]] || continue
  matches+=("${candidate_name}")
done

if [[ ${#matches[@]} -eq 1 ]]
then
  printf '%s\n' "${matches[0]}"
  exit 0
fi

if [[ -n "${requested_path}" ]]
then
  echo "verify_tap_worktree: ${tap_name} resolves to ${requested_path}" >&2
else
  echo "verify_tap_worktree: ${tap_name} is not installed" >&2
fi
echo "verify_tap_worktree: expected the checkout under test at ${expected_path}" >&2
if [[ ${#matches[@]} -gt 1 ]]
then
  echo "verify_tap_worktree: multiple private tap aliases resolve to this checkout:" >&2
  for match in "${matches[@]}"
  do
    echo "  - ${match}" >&2
  done
  echo "verify_tap_worktree: select one with HOMEBREW_TAP_NAME" >&2
else
  echo "verify_tap_worktree: run 'just link-tap' before retrying" >&2
fi
exit 1
