# RisingWave contribution notes (our working memory)

Distilled from the Developer Guide (https://risingwavelabs.github.io/risingwave/, source in
`docs/dev/src/`), `CONTRIBUTING.md`, `CLAUDE.md`, `.agents/PR_LABELING.md` and
`.github/pull_request_template.md`. Re-check those files if anything here looks stale.

## Repos and branches
- Fork: `yashaggarwal85d/risingwave` (`origin`). Upstream: `risingwavelabs/risingwave` (`upstream`).
- Cut every fix branch from fresh `upstream/main`, NOT from the notes branch
  (`claude/funny-sagan-zxrnrj`), so this file never lands in an upstream PR:
  `git fetch upstream main && git checkout -b fix/<topic> upstream/main`
- Upstream PRs are opened from the fork (head `yashaggarwal85d:<branch>`, base `risingwavelabs:main`).

## Authorship (user's rule)
- All commits are authored and committed as Yash Aggarwal
  `68061195+yashaggarwal85d@users.noreply.github.com` (set via `git config user.name/user.email`
  in each fresh clone). Nothing under Claude's name: no `Co-Authored-By: Claude`, no
  `Claude-Session` trailers in commits, and no "Generated with Claude Code" lines in PR bodies.
- Every PR description ends the "What's changed and what's your intention?" section with this
  exact line: `AI-assisted; I reviewed and understand all changes.`

## Finding work
- Start with `good first issue` (https://github.com/risingwavelabs/risingwave/contribute).
- Discuss design first for anything non-trivial: comment on the issue (or Slack / Discussions)
  before coding. Check the issue isn't already assigned or has an open PR.

## PR rules
- Title must use a conventional-commit prefix (checked by CI, see `.github/pr-title-checker-config.json`):
  `feat | fix | doc | refactor | style | perf | test | build | ci | chore | revert`,
  optional scope, e.g. `fix(frontend): ...`, `feat(expr): ...`.
- Body: follow `.github/pull_request_template.md` (keep the CLA line at top; "What's changed and
  what's your intention?" is mandatory; `- Closes #<issue>`; checklist; release note if user-facing).
- Sign the CLA (bot asks on first PR).
- Fork PRs: Buildkite does NOT run until a maintainer comments `/approve-run-bk`, and it must be
  re-approved after every push. So push fewer, well-validated commits. Ask reviewers politely;
  `@`-mention people who recently touched the files.
- Labels (`.agents/PR_LABELING.md`): only add labels that exist in the live label list; add narrow
  `ci/run-*` labels for affected areas; never `ci/pr/run-selected` on non-draft PRs; never remove
  pre-existing labels; `user-facing-changes` only for real SQL/connector/config/behavior changes
  that need docs; `breaking-change` only for real breakage. External contributors may lack
  permission to set labels: then ask the maintainer in the PR.

## Environment / tooling
- Toolchain pinned in `rust-toolchain` (nightly). Deps: cmake, protobuf-compiler, lld, tmux, psql,
  libssl-dev, libsasl2-dev, libblas/lapack-dev, libomp-dev, parallel. Setup script: `.claude/setup-dev-env.sh`.
- Tools: cargo-make (`./risedev` wraps it), cargo-nextest, cargo-hakari, cargo-sort, sqllogictest-bin, typos.
- Low memory: `CARGO_BUILD_JOBS=2`. Profiles: `dev` default; `release` via `./risedev configure`.

## Commands
- Build: `./risedev b`. Check everything (fmt, clippy, sort, hakari, typos): `./risedev c` — run before pushing.
- Unit tests: `./risedev test` (nextest) or `cargo nextest run -p <crate> <filter>`.
  New tests preferably as integration tests under `tests/integration_tests/*.rs`; use `expect_test`.
- Parser tests: `./risedev update-parser-test`. Planner tests: `./risedev run-planner-test [name]`,
  update with `./risedev dapt`.
- Config changes under `src/common/src/config`: `./risedev generate-example-config`.
- DocSlt (SQL in rustdoc): `./risedev docslt -p <pkg>` then `./risedev slt-generated -p 4566 -d dev`.
- E2E: `./risedev d [profile]` (tmux, logs in `.risingwave/log`), `./risedev psql -c "..."`,
  `./risedev slt './e2e_test/path/**/*.slt'`, `./risedev slt-clean <file>` after failures, `./risedev k`
  to stop, `./risedev clean-data` on decode errors. Playground (single process): `./risedev p`.
- Connector tests: profiles in `risedev.yml` start Kafka/MySQL/etc.; SLT uses `system ok` +
  `control substitution on` + `RISEDEV_*` env vars; keep full lifecycle in one file. See
  `.agents/skills/risingwave-slt-authoring/SKILL.md` (blank-line rules, madsim guards, coverage check
  `python3 e2e_test/check_slt_coverage.py -d`).
- Deterministic simulation: `./risedev stest`, `./risedev sslt -- '<glob>'`, `./risedev sit-test <name>`,
  reproduce with `MADSIM_TEST_SEED=<n>`.
- Backwards compat: `./risedev backwards-compat-test` (label `ci/run-backwards-compat-tests`).
- CI failure triage: `.agents/skills/fix-buildkite-ci/SKILL.md`.

## Code map (src/)
frontend (parser/binder/planner/optimizer, planner_test), stream (actors/executors),
batch, storage (Hummock LSM on S3/MinIO), meta (catalog, barriers, scheduling), expr (functions via
`#[function]`/`#[aggregate]` macros), connector (sources/sinks), common, prost (protobuf), cmd_all
(`risingwave` binary), risedevtool. Use `cargo expand -p <crate>` to read macro output.
Architecture: Frontend (stateless, PG wire) -> ComputeNode (executes), Compactor, MetaServer.
Streaming uses barrier-based checkpointing; state stored via relational tables in Hummock.
Design docs: `docs/dev/src/design/` (streaming overview, backfill, checkpoint, keys, state store, ...).

## Our workflow for each issue
1. Read the issue + linked discussion, reproduce (SLT or unit test) before fixing.
2. Branch from `upstream/main`; minimal focused change; follow surrounding style; English comments.
3. Add a regression test (SLT in `e2e_test/`, planner test, or unit test).
4. Run targeted tests + `./risedev c` (at least `cargo fmt`, clippy on touched crates).
5. Push to fork, open PR with template + conventional title; ask for `/approve-run-bk`.
