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
- **Cloud Providers**: GCP under `live/prod/gcp/`; Databricks under `live/prod/databricks/`. Each provider has its own `provider.hcl` that generates the provider block.
- **State Backend**: All units use the GCS backend (`matabar-prod-tfstate`) defined in `root.hcl`.
- **Bootstrap Tier**: `projects/matabar-prod/project` and `bootstrap/tfstate` intentionally override `remote_state` to a **local** backend. Do NOT remove these overrides — they break the bootstrap ordering (the project and the state bucket must exist before GCS-backed state is usable).
- **Apply Order**: GCP: project -> tfstate bucket -> network -> vm. Databricks Lakebase is independent (see `README.md`).
- **Secrets**: Never commit SSH private keys, Databricks CLI credentials (`~/.databrickscfg`), `*.tfstate`, or `*.tfvars`. Databricks auth uses the CLI profile `matabar` via `auth_type = "databricks-cli"` (override with `TF_VAR_databricks_profile`). SSH access is firewalled to a single source IP via `ssh_source_ranges`.
- **OpenTofu + Databricks**: The Databricks provider works with OpenTofu but is considered experimental upstream. Pin provider versions in modules.

## Workflow & Git
- **Branching**: 
    - Mandatory `feature/<name>` branches.
    - **NO DIRECT COMMITS TO MAIN**: Committing directly to the `main` branch is strictly forbidden. 
    - **Enforcement**: This is enforced via a local git pre-commit hook. Run `git config core.hooksPath .githooks` to set it up. All changes must be merged via pull requests or internal branch merges following a successful plan and validation.
- **Commits**: Strict **Conventional Commits**.
- **Atomicity**: One logical change per commit.
