---
name: warp-dev-environment
description: Use the repo-local flake.nix and direnv-provided development shell when working in the Warp repository. Trigger when Codex is building, testing, running, or debugging Warp and needs to choose environment setup commands, avoid redundant bootstrap/toolchain installation, or recover from missing development tools.
---

# Warp Dev Environment

## Environment Assumption

- Assume the current Codex shell is already inside the Warp development environment loaded by `direnv` from `.envrc` and `flake.nix`.
- Run commands from the repository root unless the task requires a narrower working directory.
- Prefer the tools already available in the active shell. Do not start a nested `nix develop` session for normal build, test, or inspection work.

## Avoid Redundant Setup

- Do not run `./script/bootstrap`, `direnv allow`, `direnv reload`, `nix develop`, `rustup`, `cargo install`, package-manager installs, or toolchain setup commands unless the user asks or a required command is genuinely missing.
- If a tool is missing, first inspect the environment with non-mutating checks such as `command -v cargo`, `command -v rustc`, `direnv status`, or `nix flake show`. Report the missing tool and the likely environment issue before changing setup.
- Treat `flake.nix` as the source of development-shell dependencies. Avoid adding ad hoc local install instructions when the dependency belongs in the flake.

## Build And Test Workflow

- Use the repo scripts and Cargo commands from the active environment:
  - `./script/run` to build and run Warp through the repository script.
  - `cargo run` for direct app runs.
  - `cargo nextest run -p <crate>` for targeted Rust test validation.
  - `cargo nextest run --no-fail-fast --workspace --exclude command-signatures-v2` for broad workspace tests.
  - `./script/format` and `cargo clippy --workspace --all-targets --all-features --tests -- -D warnings` before review-oriented changes.
- Prefer targeted tests while iterating. Reserve `./script/presubmit` for broad final validation or when the user asks for a full pre-submit check.

## Nix-Specific Notes

- The flake provides the development shell for macOS and Linux. Treat package outputs as Linux-oriented unless the flake says otherwise.
- If `Cargo.lock` git dependencies or generated proto crates behave differently under Nix, inspect `flake.nix` before changing Cargo configuration; the flake may already vendor or patch generated sources for Nix builds.
