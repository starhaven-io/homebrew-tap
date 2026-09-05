# Agent Instructions for starhaven-io/homebrew-tap

Most importantly, run the narrowest relevant Homebrew verification before
finishing any change. For cask edits, start with
`brew audit --online --strict starhaven-io/tap/<token>`; for
repository-wide syntax changes, run `brew test-bot --tap starhaven-io/tap --only-tap-syntax`.

## Project overview

This is the official Homebrew tap for starhaven.io software. It is a
cask-only tap: do not add Formula files or formula-specific workflows here.

Unlike Homebrew/brew, this repository does not vendor its own `brew` command.
Use the active Homebrew installation on `PATH` unless the task specifically
requires another Homebrew checkout.

Current Homebrew audits casks by token rather than by local file path. Before
trusting token-based checks, verify that `brew --repo starhaven-io/tap` points at
the checkout you are editing; otherwise the command audits the installed tap
checkout, not this working tree.

For a second checkout or worktree, run `just link-tap` once. Checks discover a
unique private alias that resolves to this checkout when the canonical tap
points elsewhere. Set `HOMEBREW_TAP_NAME` to select an alias explicitly when
more than one exists. The helper refuses the canonical owner and will not
replace an existing tap path. Homebrew checks fail closed when no unique alias
resolves to this checkout.

## Required checks

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

- Run `zizmor --persona auditor .` when available.
- Run `pinprick audit .` when workflow permissions, action pins, or runner
  behavior changes.

Before committing README link changes:

- Run `just lychee`.

The repository test suite covers exact cask inventory/platform routing,
invalid and symlinked cask inputs, local tap alias safety, and publisher update
content and release provenance. Fleet's required commit-policy workflow and the
managed local hook enforce DCO sign-offs. Run the repository tests with
`just test`; `just check` adds Homebrew syntax and all available workflow,
shell, supply-chain, and link linters.

The audit jobs in `ci.yml` provide the always-running pull-request aggregate
consumed by `conclusion`. Fleet-rendered standalone audit/link workflows retain
their separate push, SARIF, and scheduled responsibilities. Preserve both roles
when changing the workflow topology; identical tools do not make the triggers
or reporting contracts interchangeable.

Keep `Verify publisher cask` as a separately required, main-targeted
`pull_request_target` check. It must execute only base-branch code, treat
proposed cask blobs as data, and retain read-only permissions. The `bump-`
and `fleet-sync-` branch prefixes are reserved for publisher automation.
Bot-authored pull requests outside those lowercase namespaces fail closed.

## Repository structure

- `Casks/`: Homebrew cask Ruby files. This is the only package definition
  directory in this tap.
- `.github/workflows/`: CI, workflow security checks, and cask
  audit/fetch/install tests.
- `lychee.toml`: README link-check configuration.
- `README.md`: user-facing tap overview and cask list.

## Project-specific notes

### PR flow notes

- Keep diffs focused. Avoid unrelated version bumps, README churn, or workflow
  rewrites while touching a cask.
- PRs are squash-merged with the PR number appended.

### Cask guidelines

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

### Workflow guidelines

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

## Safety / do-not-touch rules

1. Keep this tap cask-only. Do not add Formula files or formula-specific
   workflows.
2. Do not use mutable cask URLs, `latest` release URLs, or `sha256 :no_check`.
3. Before trusting token-based Homebrew checks, verify that
   `brew --repo starhaven-io/tap` points at the checkout you are editing.
4. Pin `Homebrew/actions/*` to a full commit SHA and keep the published CalVer
   tag in the adjacent version comment.

<!-- fleet:block commit-and-pr-conventions -->

## Commit and PR conventions

- Conventional Commits: `type(scope): description`. Valid types: `feat`,
  `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.
  Mark a breaking change with `!` before the colon (`feat!:`,
  `feat(scope)!:`).
- Commits require DCO sign-off. Make all commits with `git commit -s` (enforced
  by the `.githooks/commit-msg` hook; run `just install-hooks` once per clone).
- Do not identify an AI tool or model as an author, co-author, committer, or
  signatory of a commit. Do not name an AI tool or model in `Co-authored-by`,
  `Assisted-by`, `Co-developed-by`, `Generated-by`, or similar trailers. Human
  `Co-authored-by` trailers are allowed.
- Never commit directly to `main`; create a feature branch and open a PR.
- PR descriptions should contain a concise summary of changes. Do not add a
  standalone test-plan section or checklists.
- When AI/LLM was used to generate or assist with a pull request, the initial
  PR description must end with exactly one unformatted line as the last line of
  the PR body: `AI disclosure: <model> with <how the output was verified>.`
  This is PR body text, not a commit trailer. Omit the line when no AI/LLM was
  used.
- Name the model as its vendor names it, for example `Claude Opus 5`. Do not
  also name a tool or harness unless the harness is the only identifier. Do not
  describe what the AI did.
- Do not format the disclosure as a heading, bullet, bold label, or horizontal
  rule, and do not add a promotional "generated with" footer.
- Keep each prose paragraph in a PR description on one source line. Do not
  hard-wrap PR body prose like a commit message; preserve intentional Markdown
  line breaks in lists, code blocks, and other structured content.
- Comments must earn their keep: a comment states a constraint or rationale the
  code cannot express. Never add comments that narrate what the code does,
  restate names, or explain a change to its reviewer.

<!-- fleet:end -->
