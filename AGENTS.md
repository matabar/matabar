# AGENTS.md

## Core Principles
- **Agent-First**: This file is the primary source of truth for AI agent behavior in this repo.
- **Strict Compliance**: All instructions here are mandatory.

## Planning & Strategy
- **Phased Planning**: Every non-trivial task MUST start with a phased implementation plan.
- **Structure**: Plans must be broken down into Chapters/Phases, each specifying:
    - Dedicated feature branches.
    - Atomic commits (following Conventional Commits).
    - Documentation updates per step.
- **Abstraction**: Plans should focus on architectural decisions and workflow, AVOIDING literal code snippets to prevent redundancy and keep plans focused on intent.

## Code Style & Conventions
- **Tooling**: Use `opentofu` and `terragrunt`.
- **Formatting**: Mandatory `terragrunt hclfmt`.
- **Naming**: kebab-case for resources, underscores for variables.
- **Documentation**: 
    - Maintain `README.md` and `AGENTS.md` in sync with all changes.
    - Plan documentation updates as first-class citizens in every task.

## Infrastructure Conventions
- **Cloud Providers**: GCP under `live/prod/gcp/`. The provider block is generated via `provider.hcl`.
- **State Backend**: All units use the GCS backend (`matabar-prod-tfstate`) defined in `root.hcl`.
- **Bootstrap Tier**: `projects/matabar-prod/project` and `bootstrap/tfstate` intentionally override `remote_state` to a **local** backend. Do NOT remove these overrides — they break the bootstrap ordering (the project and the state bucket must exist before GCS-backed state is usable).
- **Apply Order**: project -> tfstate bucket -> github-wif -> dns/matabar-online and github/repos. The first three are bootstrap-tier (local state). `github-wif` is excluded from CI `plan` and `apply`. DNS and GitHub use the GCS backend. Do not apply from a cloud agent; the owner applies locally.
- **Dependency mocks**: Every `dependency` block that feeds `inputs` must define `mock_outputs` for each referenced output and `mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]`. Mocks are never used on `apply`.
- **Bootstrap outputs**: Never read `dependency.*.outputs` from a local-backend (bootstrap-tier) unit. Their state exists only on the owner's machine, so CI and `validate -backend=false` cannot read it. Take shared values (project id, state bucket) from `live/prod/env.hcl` and use a `dependencies` block for ordering.
- **Live Layout**: Units live under `live/prod/gcp/europe-west3/` (`projects/matabar-prod/` and `bootstrap/`).
- **Secrets**: Never commit `*.tfstate`, `*.tfvars`, `.env`, PEM files, or credential JSON. There is no VM and no SSH key in this repo.

## Workflow & Git
- **Branching**: 
    - Mandatory `feature/<name>` branches.
    - **One concern per pull request**. Do not mix unrelated changes. A PR must be reviewable on its own.
    - **Stack dependent work**. Branch from the previous PR and target that branch. Independent work branches from `main`.
    - **NO DIRECT COMMITS TO MAIN**: Committing directly to the `main` branch is strictly forbidden. 
    - **Enforcement**: This is enforced via a local git pre-commit hook. Run `git config core.hooksPath .githooks` to set it up. All changes must be merged via pull requests or internal branch merges following a successful plan and validation.
- **Commits**: Strict **Conventional Commits**.
- **Atomicity**: One logical change per commit.
- **Worktrees**: When creating git worktrees (`/worktree`, split-to-PRs, parallel feature work):
    - Use the **git branch name** as the worktree directory name (slashes preserved).
    - Do **not** prefix with PR numbers (`pr1-`, `pr2-`, etc.).
    - Path pattern: `~/.cursor/worktrees/<WORKTREE_ID>/<branch-name>/` (e.g. `feature/dns-zone`, not `pr1-feature/dns-zone`).
    - For multi-repo batches under one `WORKTREE_ID`, keep the branch-name leaf; do not insert numeric PR ordinals.
