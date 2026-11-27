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
- **Local checks**: Run `mise run check` (or `.github/scripts/check.sh`) before pushing. It runs the PR checks (fmt, validate, tflint, trivy). `.tool-versions` is the only place versions live; `mise.toml` holds tasks only. When you change a check command in `pr-checks.yml`, change `.github/scripts/check.sh` in the same PR.
- **Documentation**: 
    - Maintain `README.md` and `AGENTS.md` in sync with all changes.
    - Plan documentation updates as first-class citizens in every task.

## Infrastructure Conventions
- **Cloud Providers**: GCP under `infra/live/prod/gcp/`. The provider block is generated via `provider.hcl`.
- **State Backend**: All units use the GCS backend (`matabar-prod-tfstate`) defined in `infra/root.hcl`.
- **Bootstrap Tier**: `projects/matabar-prod/project`, `bootstrap/tfstate`, and `bootstrap/github-wif` intentionally override `remote_state` to a **local** backend. Do NOT remove these overrides. The project and the state bucket must exist before GCS-backed state is usable, and CI must not rewrite its own Workload Identity trust.
- **Apply Order**: project -> tfstate bucket -> github-wif -> dns/matabar-online and github/repos. The first three are bootstrap-tier (local state). `github-wif` is excluded from CI `plan` and `apply`. DNS and GitHub use the GCS backend and are applied by the Deploy workflow after merge. The owner applies the bootstrap tier locally; never from a cloud agent.
- **Dependency mocks**: Every `dependency` block that feeds `inputs` must define `mock_outputs` for each referenced output and `mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]`. Mocks are never used on `apply`.
- **Bootstrap outputs**: Never read `dependency.*.outputs` from a local-backend (bootstrap-tier) unit. Their state exists only on the owner's machine, so CI and `validate -backend=false` cannot read it. Take shared values (project id, state bucket) from `infra/live/prod/env.hcl` and use a `dependencies` block for ordering.
- **Monorepo**: `matabar/matabar` holds infrastructure (`infra/`) and the static site (`apps/site/`, published by the Pages workflow on `apps/site/**`). The former `personal-infra` and `matabar.online` repositories are retired; do not recreate them. Their resources were forgotten from the GitHub unit's state (`removed` blocks, since dropped); never reuse those addresses.
- **Repository Layout**: The root holds only repo-wide files (`.github/`, `.githooks/`, `AGENTS.md`, `README.md`, `CODEOWNERS`, `.tool-versions`, `mise.toml`, `.gitignore`, `.env.example`). Deployables live under `apps/<name>` (today `apps/site`). Infrastructure lives under `infra/` (`root.hcl`, `live/`, `modules/`, `.tflint.hcl`, `trivy.yaml`). Shared code goes under `packages/<name>`, created when the first one exists. A new project adds a directory; nothing existing moves. Terragrunt runs from `infra/`, and `get_repo_root()` paths carry the `infra/` prefix.
- **Live Layout**: Units live under `infra/live/prod/gcp/europe-west3/` (`projects/matabar-prod/` and `bootstrap/`).
- **PR Checks**: `.github/workflows/pr-checks.yml` starts with a `changes` job that maps changed paths to projects (`infra`, `site`); `.github/**` and `.tool-versions` affect every project. Project jobs skip when unaffected, keep their names, and every job must be listed in the `needs` of the final `ci` job, which always runs and fails on any failed or cancelled job. Only `plan-comment` may write to the PR; fork PRs get no cloud credentials.
- **Secrets**: Never commit `*.tfstate`, `*.tfvars`, `.env`, PEM files, or credential JSON. There is no VM and no SSH key in this repo.
- **Public repository**: `matabar/matabar` is public. Never commit personal data either: email addresses, home or office IPs, or anything identifying beyond the GitHub login. Commit with the GitHub noreply address.

## Workflow & Git
- **Branching**: 
    - Mandatory `feature/<name>` branches.
    - **One concern per pull request**. Do not mix unrelated changes. A PR must be reviewable on its own.
    - **Stack dependent work**. Branch from the previous PR and target that branch. Independent work branches from `main`.
    - **NO DIRECT COMMITS TO MAIN**: Committing directly to the `main` branch is strictly forbidden. 
    - **Enforcement**: This is enforced via a local git pre-commit hook. Run `git config core.hooksPath .githooks` to set it up. All changes must be merged via pull requests or internal branch merges following a successful plan and validation.
- **Commits**: Strict **Conventional Commits**.
- **Commit scopes**: One stable scope per project, so history stays greppable as projects are added. Scope is optional, but if present it must be one of:
    - `infra`: everything under `infra/` (units, modules, state, DNS, GitHub settings).
    - `site`: `apps/site`.
    - `ci`: `.github/workflows`, `.github/actions`, `.github/scripts`.
    - `deps`: dependency and tool-version bumps (`dependabot.yml`, `.tool-versions`).
    - `repo`: repo-wide files (`AGENTS.md`, `README.md`, `.githooks/`, `CODEOWNERS`, `mise.toml`, `.gitignore`).
    - A new `apps/<name>` or `packages/<name>` uses its directory name as scope. Do not use sub-areas such as `github`, `dns`, or `hooks`; put those in the description.
    - Enforced by `.githooks/commit-msg`, which skips merge, revert, fixup, squash, and amend subjects. Keep it in sync with this list.
- **Atomicity**: One logical change per commit.
- **Worktrees**: When creating git worktrees (`/worktree`, split-to-PRs, parallel feature work):
    - Use the **git branch name** as the worktree directory name (slashes preserved).
    - Do **not** prefix with PR numbers (`pr1-`, `pr2-`, etc.).
    - Path pattern: `~/.cursor/worktrees/<WORKTREE_ID>/<branch-name>/` (e.g. `feature/dns-zone`, not `pr1-feature/dns-zone`).
    - For multi-repo batches under one `WORKTREE_ID`, keep the branch-name leaf; do not insert numeric PR ordinals.
