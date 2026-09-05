#!/usr/bin/env bash
set -euo pipefail

tap_name="${1:-starhaven-worktree/tap}"
checkout="${2:-${PWD}}"

if [[ ! "${tap_name}" =~ ^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$ ]]
then
  echo "link_tap_worktree: invalid tap name: ${tap_name}" >&2
  exit 1
fi
if [[ ! -d "${checkout}" ]]
then
  echo "link_tap_worktree: checkout does not exist: ${checkout}" >&2
  exit 1
fi

owner="${tap_name%%/*}"
repository="${tap_name##*/}"
if [[ "${owner}" == "starhaven-io" ]]
then
  echo "link_tap_worktree: refusing to claim the canonical starhaven-io owner" >&2
  exit 1
fi

checkout="$(cd "${checkout}" && pwd -P)"
brew_repository="$(brew --repository)"
taps_root="${brew_repository}/Library/Taps"
mkdir -p "${taps_root}"
taps_root="$(cd "${taps_root}" && pwd -P)"
owner_path="${taps_root}/${owner}"
if [[ -L "${owner_path}" ]]
then
  echo "link_tap_worktree: refusing symlinked tap owner path: ${owner_path}" >&2
  exit 1
fi
if [[ -e "${owner_path}" && ! -d "${owner_path}" ]]
then
  echo "link_tap_worktree: tap owner path is not a directory: ${owner_path}" >&2
  exit 1
fi
mkdir -p "${owner_path}"
resolved_owner_path="$(cd "${owner_path}" && pwd -P)"
if [[ "${resolved_owner_path}" != "${owner_path}" ]]
then
  echo "link_tap_worktree: tap owner path escaped its namespace: ${owner_path}" >&2
  exit 1
fi
tap_path="${owner_path}/homebrew-${repository}"

if [[ -L "${tap_path}" ]]
then
  linked_path="$(cd "${tap_path}" && pwd -P)"
  if [[ "${linked_path}" != "${checkout}" ]]
  then
    echo "link_tap_worktree: ${tap_path} already links to ${linked_path}" >&2
    exit 1
  fi
elif [[ -e "${tap_path}" ]]
then
  echo "link_tap_worktree: refusing to replace existing path: ${tap_path}" >&2
  exit 1
else
  ln -s "${checkout}" "${tap_path}"
fi

echo "Linked ${tap_name} to ${checkout}"
echo "Run: HOMEBREW_TAP_NAME=${tap_name} just check"
