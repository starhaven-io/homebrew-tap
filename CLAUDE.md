# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the official [Homebrew](https://brew.sh) tap (`starhaven-io/homebrew-tap`) for [starhaven.io](https://starhaven.io) software. All packages are casks (no formulae).

## Repository Structure

- `Casks/` — Homebrew cask Ruby files (the only code in this repo)
- `.github/workflows/` — CI (audit, fetch, install tests) and autobump automation

## Common Commands

```bash
# Audit a cask for style and correctness
brew audit --cask --online --strict Casks/pinprick.rb

# Check tap syntax
brew test-bot --only-tap-syntax

# Install a cask from local path
brew install --cask Casks/pinprick.rb

# Check for outdated casks via livecheck
brew livecheck --tap starhaven-io/homebrew-tap

# Bump a cask version (creates PR automatically)
brew bump --no-fork --open-pr --cask <cask-token>
```

## Cask Conventions

- `zap` stanzas list all known application data paths for clean removal.
- `livecheck` blocks are used where upstream provides consistent release URLs.

## CI

PRs trigger `brew generate-cask-ci-matrix` which audits, fetches, and optionally installs each changed cask. Push to `main` runs syntax-only checks. The autobump workflow runs every 2 hours to check for new upstream releases.

## Commit Conventions

Conventional Commits format: `type(scope): description`

Common types: `feat`, `fix`, `refactor`, `docs`, `ci`, `chore`

All commits must:
- Include a `Signed-off-by` trailer for DCO sign-off
- Include a `Co-authored-by: Claude Opus 4.7 (1M context) <noreply@anthropic.com>` trailer when authored with Claude, placed after `Signed-off-by`

## Git Workflow

- Never commit directly to main — always create a feature branch and open a PR
- PRs are squash-merged with the PR number appended

## PR Conventions

- PR descriptions should contain only a summary of the changes — no test plan sections, no bot attribution, no "Generated with Claude Code" footers
