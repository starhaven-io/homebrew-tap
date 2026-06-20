# Agent Instructions for starhaven-io/homebrew-tap

Most importantly, run the narrowest relevant Homebrew verification before
finishing any change. For cask edits, start with
`brew audit --online --strict starhaven-io/tap/<token>`; for
repository-wide syntax changes, run `brew test-bot --tap starhaven-io/tap --only-tap-syntax`.

This is the official Homebrew tap for starhaven.io software. It is a
cask-only tap: do not add Formula files or formula-specific workflows here.

Unlike Homebrew/brew, this repository does not vendor its own `brew` command.
Use the active Homebrew installation on `PATH` unless the task specifically
requires another Homebrew checkout.

Current Homebrew audits casks by token rather than by local file path. Before
trusting token-based checks, verify that `brew --repo starhaven-io/tap` points at
the checkout you are editing; otherwise the command audits the installed tap
checkout, not this working tree.

## Required Checks

Before committing cask changes:

- Run `brew audit --online --strict starhaven-io/tap/<token>` for each
  changed cask.
- Run `brew fetch --retry --force starhaven-io/tap/<token>` when a URL,
  version, or checksum changes.
- Run `brew install Casks/<token>.rb` when the artifact layout,
  `app`, `binary`, completions, dependencies, or `zap` behavior changes.
- Run `brew uninstall --force --zap Casks/<token>.rb` after install
  tests when the cask includes `zap` entries.
- Run `brew test-bot --only-tap-syntax` for repository-wide syntax coverage.

Before committing workflow changes:

- Run `actionlint .github/workflows/*.yml`.
- Run `zizmor .` when available.
- Run `pinprick audit .` when workflow permissions, action pins, or runner
  behavior changes.

## Repository Structure

- `Casks/`: Homebrew cask Ruby files. This is the only package definition
  directory in this tap.
- `.github/workflows/`: CI, workflow security checks, retry automation, and
  cask audit/fetch/install tests.
- `.github/zizmor.yml` and `.github/actionlint.yaml`: workflow lint policy.
- `README.md`: user-facing tap overview and cask list.

## Cask Guidelines

1. Keep every package as a cask. Do not introduce formulae.
2. Prefer immutable GitHub release URLs with explicit versions and SHA-256
   checksums. Do not use mutable `latest` URLs or `sha256 :no_check`.
3. Keep architecture and OS selectors explicit when upstream ships different
   artifacts per platform.
4. For GUI apps, include `app`, accurate `depends_on` constraints, and a
   complete `zap` stanza for known application state.
5. For CLI artifacts, include `binary` and generated shell completions when
   upstream supports them.
6. Keep `desc` values short, user-facing, and aligned with upstream project
   descriptions.
7. Add or update `livecheck` blocks only when upstream has stable release URLs
   that Homebrew cannot infer reliably.
8. Update `README.md` whenever casks are added, removed, renamed, or materially
   repositioned.

## Workflow Guidelines

1. Pin third-party GitHub Actions to full commit SHAs. Keep the upstream version
   comment next to the pin when practical.
2. Use least-privilege `permissions`; prefer top-level `permissions: {}` plus
   job-level grants.
3. Use `persist-credentials: false` for checkout steps unless a later step must
   push with the checkout token.
4. Keep shell steps in `bash` with `set -euo pipefail` semantics, either through
   workflow defaults or inside multi-line scripts.
5. Quote shell variables and pass untrusted GitHub context through environment
   variables before using it in scripts.
6. Leave a short explanatory comment immediately above each `shellcheck disable`.
7. Keep security scanning workflows useful on pull requests and pushes to
   `main`.

## Commit Style

Use Conventional Commits:

- `feat(scope): description`
- `fix(scope): description`
- `refactor(scope): description`
- `docs(scope): description`
- `ci(scope): description`
- `chore(scope): description`

All commits must include a `Signed-off-by` trailer for DCO sign-off.

When authored with an AI coding agent, include the appropriate
`Co-Authored-By` trailer after `Signed-off-by`:

- Codex: `Co-Authored-By: Codex Opus 4.8 (1M context) <noreply@anthropic.com>`
- Claude: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`

Bump the model version in the trailer as newer models ship.

## Git and PR Flow

1. Never commit directly to `main`; create a feature branch and open a PR.
2. Keep diffs focused. Avoid unrelated version bumps, README churn, or workflow
   rewrites while touching a cask.
3. PR descriptions should contain only a concise summary of the changes. Do not
   add test plan sections, bot attribution, or "Generated with ..." footers.
4. PRs are squash-merged with the PR number appended.
