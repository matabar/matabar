# matabar

Monorepo for the `matabar.online` stack: GCP foundation, DNS, GitHub configuration, and the static site, managed with OpenTofu and Terragrunt.

This repository is public. Its history was rewritten on 2026-11-27 to drop
author email addresses and the retired VM stack's SSH allowlist IPs. Never
commit personal data.

## Layout

The root holds only repo-wide files (`.github/`, `.githooks/`, `AGENTS.md`, `README.md`, `CODEOWNERS`, `.tool-versions`, `mise.toml`, `package.json`, `nx.json`, `.gitignore`, `.env.example`). Each project lives in its own directory and keeps its own README; this file stays a map.

| Path | Project | Docs |
| --- | --- | --- |
| `infra/` | GCP project, state bucket, DNS, GitHub settings (OpenTofu + Terragrunt) | [infra/README.md](infra/README.md) |
| `apps/site/` | Static site at `matabar.online`, published to GitHub Pages | [apps/site/README.md](apps/site/README.md) |

CI lives in `.github/workflows/`: `pr-checks`, `deploy`, `drift` and `terragrunt-run` serve infra (see its README); `pages` publishes the site.

Future deployables go under `apps/<name>` and shared code under `packages/<name>`. A new project adds a directory; nothing existing moves (see [Adding a project](#adding-a-project)).

## Contributing

- **Branches**: work on `feature/<name>`; never commit directly to `main`. One concern per pull request. Stack dependent work on the previous branch.
- **Commits**: Conventional Commits. The scope is optional; if present it is one of `infra`, `site`, `ci`, `deps`, `repo`, or a new `apps/<name>` or `packages/<name>` directory name. The full list is in [AGENTS.md](AGENTS.md) and is enforced by `.githooks/commit-msg`.
- **Documentation**: each project documents itself in its own README. Update the README of the project you change, and keep this file and `AGENTS.md` in sync.

## Nx and pull request checks

[Nx](https://nx.dev) (pinned in `package.json`, installed with `npm ci`) is the monorepo tool. Each project has a `project.json` that declares its checks as targets with their inputs; `nx.json` holds the shared named inputs (`.tool-versions`, CI config, `nx.json`). Nx Cloud is never connected (`neverConnectToCloud`); caching is local only (`.nx/`, gitignored).

| Project | Targets | Tags |
| --- | --- | --- |
| `infra` | `fmt`, `validate`, `tflint`, `trivy` | `type:infra`, `scope:platform` |
| `site` | `html`, `links`, `links-external` (advisory, needs the network) | `type:app`, `scope:site` |

**Affected detection.** A project is affected when a changed file is in its root, or is a shared input: `.tool-versions`, `.github/workflows`, `.github/actions`, `.github/scripts`, `.github/dependabot.yml`, `nx.json`, and (for `site`) `package.json` and `package-lock.json`. A change to the lockfile affects every project. Other paths, such as the root docs, affect none. `.tool-versions` counts as an input of every project until per-project tool pins land.

Every pull request, and every push that is not to `main`, starts with a `changes` job: it runs `nx show projects --affected` and the other jobs read the result. `nrwl/nx-set-shas` supplies the base: on a pull request the merge base with the target branch; on a branch push `origin/main` (this workflow never runs on `main`, so there is no earlier successful run to find). Each check is its own job (`fmt`, `validate`, `tflint`, `trivy`, `html`, `links`) running `nx affected -t <target>`, so a failure shows under its own name and unaffected jobs are skipped. A final `ci` job always runs (`re-actors/alls-green`). It fails when any job that ran failed or was cancelled, and passes when the listed jobs were skipped. It is the one check to require: a new check job is added to its `needs`.

The infra jobs (and `plan / terragrunt`) are described in [infra/README.md](infra/README.md#plan-deploy-and-drift), the site jobs in [apps/site/README.md](apps/site/README.md#checks).

Run the checks locally, before pushing:

```bash
mise install                                   # tools from .tool-versions
mise run check                                 # affected projects only (nx affected)
mise run check:all                             # every check on every project
npx nx run infra:fmt                           # one target
npx nx graph --file=graph.html                 # project graph
```

A missing tool fails its target with "command not found"; `mise install` installs them all. `tflint --init` downloads a ruleset from the GitHub API; set `GITHUB_TOKEN` if you hit its rate limit. CI installs the tools with `jdx/mise-action` and Nx with `npm ci`. Tool versions are in `.tool-versions`; Nx and html-validate are pinned by `package-lock.json`, and Dependabot bumps them.

## Adding a project

1. Create `apps/<name>` (deployable) or `packages/<name>` (shared code) with a `project.json`: `name`, `projectType`, `tags` (`type:app` or `type:package`, plus `scope:<name>`), and a target per check with `inputs` (start from `default`; add `{ "runtime": "<tool> --version" }` for tool versions). Mark deterministic targets `"cache": true`; the default is off. Use `nx:run-commands` for the commands.
2. Add the tools it needs to `.tool-versions`, give it a README, and add a commit scope (its directory name) to `AGENTS.md` and `.githooks/commit-msg`.
3. If it adds a check target that no job runs, add a job to `pr-checks.yml` that runs `nx affected -t <target>`, and list it in `ci`'s `needs` and `allowed-skips`. Targets that already have a job (for example `fmt`) run for the new project with no workflow change.
4. `nx show projects` should list it; `nx graph` should show it.

Boundary rules: tags are in place, but enforcement is deferred. Nx enforces tag constraints with the `@nx/enforce-module-boundaries` ESLint rule (JavaScript and TypeScript imports only) or the Conformance plugin (needs an Nx Enterprise licence). Neither fits a repo with no JavaScript projects. The intended rule: `type:app` may depend on `type:package`; `type:package` only on `type:package`; `type:infra` on none. Wire it when the first `packages/` project exists.

## Git Hooks

Enable local hooks (blocks direct commits to `main`, auto-formats and re-stages
HCL/TF, checks commit subjects against the scopes in `AGENTS.md`, validates on push):

```bash
git config core.hooksPath .githooks
```

## AI Agent Conventions

The official Nx agent support is committed: the Nx MCP server and skills for Claude Code (`.claude/settings.json` enables the `nx` plugin), Codex, Gemini and OpenCode (`.codex/`, `.gemini/`, `opencode.json`, `.agents/skills`, `.opencode/`). Refresh it with `npx nx configure-ai-agents`.

This repository follows strict conventions for AI agents as defined in [AGENTS.md](./AGENTS.md).

**Key Rules:**

- **No Direct Commits to Main**: All work must be performed in feature branches.
- **One Concern Per PR**: Stack dependent pull requests; do not bundle unrelated changes.
- **Phased Planning**: Every non-trivial task requires a phased plan.
- **Conventional Commits**: Strict adherence to commit message standards.
 
