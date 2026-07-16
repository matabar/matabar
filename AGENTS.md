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
- **Apply Order**: GCP: project -> tfstate bucket -> network -> compute-instance/matabar-prod.
- **Dependency mocks**: Every `dependency` block that feeds `inputs` must define `mock_outputs` for each referenced output and `mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]`. Mocks are never used on `apply`.
- **Live Layout**: Workloads live under `workloads/<type>/<name>/` (e.g. `compute-instance/matabar-prod`).
- **Secrets**: Never commit SSH private keys, DuckDNS tokens, `*.tfstate`, `*.tfvars`, or `.env`. Copy `.env.example` → `.env` at the repo root and `source` it before apply. SSH uses GCP IAP (`35.235.240.0/20`).
- **Web Stack**: VM bootstrap (Docker, nginx, certbot) is defined in `modules/gcp/compute-instance/templates/` and applied via cloud-init `user-data` on first boot. DuckDNS A record is synced by Terraform `local-exec` when the static IP changes.

## Workflow & Git
- **Branching**: 
    - Mandatory `feature/<name>` branches.
    - **NO DIRECT COMMITS TO MAIN**: Committing directly to the `main` branch is strictly forbidden. 
    - **Enforcement**: This is enforced via a local git pre-commit hook. Run `git config core.hooksPath .githooks` to set it up. All changes must be merged via pull requests or internal branch merges following a successful plan and validation.
- **Commits**: Strict **Conventional Commits**.
- **Atomicity**: One logical change per commit.
- **Worktrees**: When creating git worktrees (`/worktree`, split-to-PRs, parallel feature work):
    - Use the **git branch name** as the worktree directory name (slashes preserved).
    - Do **not** prefix with PR numbers (`pr1-`, `pr2-`, etc.).
    - Path pattern: `~/.cursor/worktrees/<WORKTREE_ID>/<branch-name>/` (e.g. `feature/network-https-ingress`, not `pr1-feature/network-https-ingress`).
    - For multi-repo batches under one `WORKTREE_ID`, keep the branch-name leaf; do not insert numeric PR ordinals.
