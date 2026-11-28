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
- **Local checks**: Run `mise run check` (affected projects) or `mise run check:all` before pushing; both call Nx. The checks are Nx targets declared in each project's `project.json` (`infra`: `fmt`, `validate`, `tflint`, `trivy`; `site`: `html`, `links`, advisory `links-external`). That is the only definition of the check commands: change them there and keep the workflow a thin caller. `.tool-versions` is the place for tool versions; Nx and html-validate are pinned by the root `package-lock.json` (installed with `npm ci`); `mise.toml` holds tasks only. Run tasks through Nx (`npx nx run`, `run-many`, `affected`), not the underlying tool.
- **Documentation**: 
    - Maintain `README.md` and `AGENTS.md` in sync with all changes.
    - Each project keeps its own README (`infra/README.md`, `apps/site/README.md`, and one per new `apps/<name>` or `packages/<name>`). Project-specific docs, runbooks and commands go there. The root `README.md` stays a short map: what the repo is, the layout, the repo-wide contribution workflow, and links to the project READMEs. Update the README of the project you change.
    - Plan documentation updates as first-class citizens in every task.

## Infrastructure Conventions
- **Cloud Providers**: GCP under `infra/live/prod/gcp/`. The provider block is generated via `provider.hcl`.
- **State Backend**: All units use the GCS backend (`matabar-prod-tfstate`) defined in `infra/root.hcl`.
- **Bootstrap Tier**: `projects/matabar-prod/project`, `bootstrap/tfstate`, and `bootstrap/github-wif` intentionally override `remote_state` to a **local** backend. Do NOT remove these overrides. The project and the state bucket must exist before GCS-backed state is usable, and CI must not rewrite its own Workload Identity trust.
- **Apply Order**: project -> tfstate bucket -> github-wif -> dns/matabar-online and github/repos. The first three are bootstrap-tier (local state). `github-wif` is excluded from CI `plan` and `apply`. DNS and GitHub use the GCS backend and are applied by the Deploy workflow after merge. The owner applies the bootstrap tier locally; never from a cloud agent.
- **Dependency mocks**: Every `dependency` block that feeds `inputs` must define `mock_outputs` for each referenced output and `mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]`. Mocks are never used on `apply`.
- **Bootstrap outputs**: Never read `dependency.*.outputs` from a local-backend (bootstrap-tier) unit. Their state exists only on the owner's machine, so CI and `validate -backend=false` cannot read it. Take shared values (project id, state bucket) from `infra/live/prod/env.hcl` and use a `dependencies` block for ordering.
- **Monorepo**: `matabar/matabar` holds infrastructure (`infra/`) and the static site (`apps/site/`, published by the Pages workflow on `apps/site/**`). The former `personal-infra` and `matabar.online` repositories are retired; do not recreate them. Their resources were forgotten from the GitHub unit's state (`removed` blocks, since dropped); never reuse those addresses.
- **Repository Layout**: The root holds only repo-wide files (`.github/`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `CODEOWNERS`, `.tool-versions`, `mise.toml`, `package.json`, `package-lock.json`, `nx.json`, `.gitignore`, `.env.example`, and the Nx agent files below). Deployables live under `apps/<name>` (today `apps/site`). Infrastructure lives under `infra/` (`root.hcl`, `live/`, `modules/`, `.tflint.hcl`, `trivy.yaml`). Shared code goes under `packages/<name>`, created when the first one exists. Every project has a `project.json` with tags (`type:app|package|infra`, `scope:<name>`) and check targets. A new project adds a directory and a `project.json`; nothing existing moves (see the root README, "Adding a project"). Boundary enforcement between tags is deferred: Nx offers it only through an ESLint rule (JS/TS) or the licensed Conformance plugin. Terragrunt runs from `infra/`, and `get_repo_root()` paths carry the `infra/` prefix.
- **Live Layout**: Units live under `infra/live/prod/gcp/europe-west3/` (`projects/matabar-prod/` and `bootstrap/`).
- **PR Checks**: `.github/workflows/pr-checks.yml` starts with a `changes` job that runs `nx show projects --affected` (script `nx-affected-projects.sh`) and outputs the affected projects as JSON; other jobs use it in `if:`. Affected detection is Nx's: a project is affected by files under its root and by its `inputs` (shared named inputs in `nx.json`: `.tool-versions`, CI config under `.github/`, `nx.json`; `site` also takes `package.json`; any lockfile change affects every project). `.tool-versions` is an input of every project until issue 40. The `title` job checks the pull request title (see Commit scopes). Each check is its own job (`fmt`, `validate`, `tflint`, `trivy`, `html`, `links`) running `nx affected -t <target>`. Base: merge base on pull requests, `origin/main` on branch pushes. Project jobs skip when unaffected, and every job must be listed in the `needs` and `allowed-skips` of the final `ci` job, which always runs and fails on any failed or cancelled job. External link checks are advisory only. `ci` is the only required status check of the `protect-main` ruleset (`required_checks`); never add individual job names there. Only `plan-comment` may write to the PR; fork PRs get no cloud credentials. Nx runs only in jobs without cloud credentials, and no Nx cache is shared between jobs (`.nx/` stays on the runner). Never connect Nx Cloud (`neverConnectToCloud` in `nx.json`).
- **Secrets**: Never commit `*.tfstate`, `*.tfvars`, `.env`, PEM files, or credential JSON. There is no VM and no SSH key in this repo.
- **Public repository**: `matabar/matabar` is public. Never commit personal data either: email addresses, home or office IPs, or anything identifying beyond the GitHub login. Commit with the GitHub noreply address.

## CI Workflows
- **Use published actions**: Workflows configure existing, well-maintained published actions (`with`, `env`). Write custom code only when no suitable action exists.
- **No inline logic**: Custom code lives in `.github/scripts/` (or a local action under `.github/actions/`), never inline. No workflow step has a multi-line `run` block, inline `actions/github-script` code, or shell logic such as `||` fallbacks; a step names a script or action and passes inputs. Expressions (`||`, `==`) in `env` and `with` are configuration and fine.
- **Local actions**: A composite `action.yml` follows the same rule: it calls published actions or a script, not inline shell.
- **Adopting an action**: Pin it to a full commit SHA with a version comment (Dependabot's `github-actions` entry keeps it current), give the job minimal permissions, and pass secrets or cloud credentials only to the official action for that purpose.
- **Tools**: Versions come from `.tool-versions`, installed by `jdx/mise-action`; Nx comes from the root lockfile via `npm ci`. Checks that also run locally are Nx targets, so CI and `mise run check` share one definition. The `.github/actions/setup-nx` composite installs tools and Nx and sets the Nx base and head with `nrwl/nx-set-shas`.

## Workflow & Git
- **Branching**: 
    - Mandatory `feature/<name>` branches.
    - **One concern per pull request**. Do not mix unrelated changes. A PR must be reviewable on its own.
    - **Stack dependent work**. Branch from the previous PR and target that branch. Independent work branches from `main`.
    - **NO DIRECT COMMITS TO MAIN**: Committing directly to the `main` branch is strictly forbidden. 
    - **Enforcement**: The `protect-main` ruleset requires pull requests. A local pre-commit hook gives early feedback; install it with `mise generate git-pre-commit --write --task=pre-commit` (the `pre-commit` task in `mise.toml`, no hand-written hook scripts). All changes must be merged via pull requests or internal branch merges following a successful plan and validation.
- **Commits**: Strict **Conventional Commits**.
- **Commit scopes**: One stable scope per project, so history stays greppable as projects are added. Scope is optional, but if present it must be one of:
    - `infra`: everything under `infra/` (units, modules, state, DNS, GitHub settings).
    - `site`: `apps/site`.
    - `ci`: `.github/workflows`, `.github/actions`, `.github/scripts`.
    - `deps`: dependency and tool-version bumps (`dependabot.yml`, `.tool-versions`).
    - `repo`: repo-wide files (`AGENTS.md`, `README.md`, `CODEOWNERS`, `mise.toml`, `.gitignore`).
    - A new `apps/<name>` or `packages/<name>` uses its directory name as scope. Do not use sub-areas such as `github`, `dns`, or `hooks`; put those in the description.
    - Enforced on the **pull request title** by the `title` job in `.github/workflows/pr-checks.yml` (`amannn/action-semantic-pull-request`), which feeds `ci`. Its `scopes` input must match this list: adding an `apps/<name>` or `packages/<name>` project adds its scope there and here, in the same PR.
    - **Merge method**: squash only (ruleset and repository settings in `infra/`), so the pull request title is the commit subject on `main` and the title check covers every commit. Individual commit messages inside a PR are not checked.
- **Atomicity**: One logical change per commit.
- **Worktrees**: When creating git worktrees (`/worktree`, split-to-PRs, parallel feature work):
    - Use the **git branch name** as the worktree directory name (slashes preserved).
    - Do **not** prefix with PR numbers (`pr1-`, `pr2-`, etc.).
    - Path pattern: `~/.cursor/worktrees/<WORKTREE_ID>/<branch-name>/` (e.g. `feature/dns-zone`, not `pr1-feature/dns-zone`).
    - For multi-repo batches under one `WORKTREE_ID`, keep the branch-name leaf; do not insert numeric PR ordinals.

## Nx Agent Support
- **Official setup**: Committed by `npx nx configure-ai-agents` for Claude Code (`.claude/settings.json` enables the `nx` plugin from `nrwl/nx-ai-agents-config`), Codex (`.codex/`), Gemini (`.gemini/`) and OpenCode (`opencode.json`, `.opencode/`), with shared skills in `.agents/skills`. The Nx MCP server is `npx nx mcp`. Refresh with `npx nx configure-ai-agents`; check with `--check=all`. Do not hand-edit the generated files or the block between the `nx configuration` markers below.
- **Nx Cloud**: The generated skills mention Nx Cloud features. They do not apply: this repo never connects to it.

<!-- nx configuration start-->
<!-- Leave the start & end comments to automatically receive updates. -->

## General Guidelines for working with Nx

- For navigating/exploring the workspace, invoke the `nx-workspace` skill first - it has patterns for querying projects, targets, and dependencies
- When running tasks (for example build, lint, test, e2e, etc.), always prefer running the task through `nx` (i.e. `nx run`, `nx run-many`, `nx affected`) instead of using the underlying tooling directly
- Prefix nx commands with the workspace's package manager (e.g., `pnpm nx build`, `npm exec nx test`) - avoids using globally installed CLI
- You have access to the Nx MCP server and its tools, use them to help the user
- For Nx plugin best practices, check `node_modules/@nx/<plugin>/PLUGIN.md`. Not all plugins have this file - proceed without it if unavailable.
- NEVER guess CLI flags - always check nx_docs or `--help` first when unsure

## Scaffolding & Generators

- For scaffolding tasks (creating apps, libs, project structure, setup), ALWAYS invoke the `nx-generate` skill FIRST before exploring or calling MCP tools

## When to use nx_docs

- USE for: advanced config options, unfamiliar flags, migration guides, plugin configuration, edge cases
- DON'T USE for: basic generator syntax (`nx g @nx/react:app`), standard commands, things you already know
- The `nx-generate` skill handles generator discovery internally - don't call nx_docs just to look up generator syntax


<!-- nx configuration end-->