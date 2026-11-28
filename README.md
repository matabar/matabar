# matabar

Monorepo for the `matabar.online` stack: GCP foundation, DNS, GitHub configuration, and the static site, managed with OpenTofu and Terragrunt.

This repository is public. Its history was rewritten on 2026-11-27 to drop
author email addresses and the retired VM stack's SSH allowlist IPs. Never
commit personal data.

## Layout

The root holds only repo-wide files (`.github/`, `.githooks/`, `AGENTS.md`, `README.md`, `CODEOWNERS`, `.tool-versions`, `mise.toml`, `.gitignore`, `.env.example`). Each project lives in its own directory and keeps its own README; this file stays a map.

| Path | Project | Docs |
| --- | --- | --- |
| `infra/` | GCP project, state bucket, DNS, GitHub settings (OpenTofu + Terragrunt) | [infra/README.md](infra/README.md) |
| `apps/site/` | Static site at `matabar.online`, published to GitHub Pages | [apps/site/README.md](apps/site/README.md) |

CI lives in `.github/workflows/`: `pr-checks`, `deploy`, `drift` and `terragrunt-run` serve infra (see its README); `pages` publishes the site.

Future deployables go under `apps/<name>` and shared code under `packages/<name>`. A new project adds a directory; nothing existing moves.

## Contributing

- **Branches**: work on `feature/<name>`; never commit directly to `main`. One concern per pull request. Stack dependent work on the previous branch.
- **Commits**: Conventional Commits. The scope is optional; if present it is one of `infra`, `site`, `ci`, `deps`, `repo`, or a new `apps/<name>` or `packages/<name>` directory name. The full list is in [AGENTS.md](AGENTS.md) and is enforced by `.githooks/commit-msg`.
- **Documentation**: each project documents itself in its own README. Update the README of the project you change, and keep this file and `AGENTS.md` in sync.

## Pull request checks

Every pull request, and every push that is not to `main`, starts with a
`changes` job. It maps the changed paths (`git diff` against the pull request
base, or `main` on a branch push) to projects:

| Project | Affected by changes under |
| --- | --- |
| `infra` | `infra/`, `.github/`, `.tool-versions` |
| `site` | `apps/site/`, `.github/`, `.tool-versions` |

Shared CI and tooling files affect every project. Other paths, such as docs,
affect none.

A final `ci` job always runs. It fails when any job that ran failed or was
cancelled, and passes when jobs were skipped. It is the one check to require:
a new project adds its jobs to the `ci` job's `needs`.

The infra jobs (`fmt`, `validate`, `tflint`, `trivy`, `plan / terragrunt`) are described in [infra/README.md](infra/README.md#plan-deploy-and-drift). The site jobs (`site-html`, `site-links`) are described in [apps/site/README.md](apps/site/README.md#checks).

Run the checks locally, before pushing, with one command:

```bash
mise run check          # or: .github/scripts/check.sh [fmt|validate|tflint|trivy|site-html|site-links]
```

It fails at once, naming the tool, if one is missing (`mise install` installs
all of them from `.tool-versions`) and warns when a version differs from the
pin. `tflint --init` downloads a ruleset from the GitHub API; set `GITHUB_TOKEN` if you hit its rate limit. Each job in `pr-checks.yml` runs `.github/scripts/check.sh <step>`, so CI and the local command are one definition; change a check in the script. In CI, a tool that is not the pinned version fails the job; locally it only warns. Tool versions are pinned in `.tool-versions`.

## Git Hooks

Enable local hooks (blocks direct commits to `main`, auto-formats and re-stages
HCL/TF, checks commit subjects against the scopes in `AGENTS.md`, validates on push):

```bash
git config core.hooksPath .githooks
```

## AI Agent Conventions

This repository follows strict conventions for AI agents as defined in [AGENTS.md](./AGENTS.md).

**Key Rules:**

- **No Direct Commits to Main**: All work must be performed in feature branches.
- **One Concern Per PR**: Stack dependent pull requests; do not bundle unrelated changes.
- **Phased Planning**: Every non-trivial task requires a phased plan.
- **Conventional Commits**: Strict adherence to commit message standards.
