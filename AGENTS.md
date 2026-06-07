# Repository Guidelines

## Project Structure & Module Organization

Warp is a Rust Cargo workspace. The main app lives in `app/`; reusable libraries live under `crates/`. Core areas include `crates/warpui/`, `crates/warpui_core/`, `crates/editor/`, `crates/warp_terminal/`, `crates/graphql/`, and `crates/persistence/`. Integration coverage is in `crates/integration/`, with app tests in `app/tests/` and fixtures beside relevant crates. Assets live in `resources/`, `images/`, and crate-local asset directories. Larger specs are stored in `specs/<issue-or-project>/` as `PRODUCT.md` and/or `TECH.md`.

## Build, Test, and Development Commands

- `./script/bootstrap`: install platform dependencies and restore shared skills.
- `./script/run`: build and run Warp locally using the repository scripts.
- `cargo run`: build and run the main app directly.
- `./script/presubmit`: run formatting, Clippy, and tests.
- `./script/format`: format Rust code using the repo configuration.
- `cargo nextest run --no-fail-fast --workspace --exclude command-signatures-v2`: run the workspace test suite with nextest.
- `cargo clippy --workspace --all-targets --all-features --tests -- -D warnings`: run lint checks as errors.

## Coding Style & Naming Conventions

Rust uses the repository `rustfmt` configuration with edition 2018. Prefer imports over long path qualifiers, inline format arguments such as `format!("{value}")`, and exhaustive `match` arms instead of `_` when practical. Context parameters named `ctx` generally come last. Remove unused parameters rather than prefixing them with `_`. Follow `.clippy.toml`; do not commit `dbg!()` and use Warp's cross-platform command and time abstractions where required.

## Testing Guidelines

Add tests for most code changes. Bug fixes need regression tests, and non-trivial logic needs unit tests. User-facing flows should use `crates/integration/` when they can be exercised end to end. Unit test files usually follow `${filename}_tests.rs` or `mod_test.rs` and are included with `#[cfg(test)]`. Run `cargo nextest run` for targeted validation and `./script/presubmit` before review. Include manual testing evidence for UI or interactive changes.

## Commit & Pull Request Guidelines

Recent commits use short imperative summaries with issue or PR references, such as `Add orchestration message display setting (#12219)` or `[QUALITY-772] Use ancestor streams for large orchestrators`. Branch names should be prefixed with your handle, for example `alice/fix-parser`.

Open PRs from `master`, keep each PR focused, link the ready issue, and use `.github/pull_request_template.md`. Add changelog markers when appropriate: `CHANGELOG-NEW-FEATURE:`, `CHANGELOG-IMPROVEMENT:`, or `CHANGELOG-BUG-FIX:`. Provide screenshots for small visual changes and a narrated recording for broader interactive changes.

## Security & Configuration Tips

Do not file public issues or PRs that disclose non-public vulnerabilities; follow `SECURITY.md`. For local server work, use `SERVER_ROOT_URL` and `WS_SERVER_URL` with `cargo run --features with_local_server`.
