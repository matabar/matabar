# personal-infra

GCP foundation for personal projects, managed with OpenTofu and Terragrunt.

This repository creates the GCP project and the remote state bucket. It does not run a virtual machine.

## Directory Structure

- `root.hcl`: Root configuration. Generates the remote state backend (GCS).
- `modules/`: Reusable OpenTofu modules, organized by cloud provider.
  - `modules/gcp/project`: GCP project and API enablement
  - `modules/gcp/storage-bucket`: Versioned GCS bucket (used for Terraform state)
- `live/`: Live infrastructure configurations.
  - `live/terragrunt.hcl`: Global Terragrunt settings
  - `live/prod/gcp/provider.hcl`: Generated Google provider block
  - `live/prod/gcp/europe-west3/region.hcl`: Region setting consumed by units
  - `live/prod/gcp/europe-west3/bootstrap/tfstate/`: GCS state bucket (local backend)
  - `live/prod/gcp/europe-west3/projects/matabar-prod/project/`: GCP project (local backend, bootstrap tier)

## State Backend

All units store state in the GCS bucket `matabar-prod-tfstate` (configured in `root.hcl`).
Two bootstrap-tier units keep their state **local** to avoid a chicken-and-egg
dependency on the bucket:

- `projects/matabar-prod/project` (the project must exist before the bucket)
- `bootstrap/tfstate` (creates the bucket itself)

## Apply Order

Nothing in this repository has been applied yet. From the repo root, with
[Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials)
from `gcloud auth application-default login`:

```bash
# 1. Project (local backend)
cd live/prod/gcp/europe-west3/projects/matabar-prod/project
terragrunt apply

# 2. State bucket (local backend)
cd ../../../bootstrap/tfstate
terragrunt apply
```

### Terragrunt dependencies

Downstream stacks reference upstream outputs via `dependency` blocks. Each dependency defines `mock_outputs` — placeholder values Terragrunt substitutes when upstream state is unavailable. Mocks are used only for `init`, `validate`, and `plan` (via `mock_outputs_allowed_terraform_commands`); `apply` always requires real upstream outputs.

This lets you run `terragrunt validate` or `plan` on a stack before its dependencies are applied (e.g. on a fresh clone). The pre-push hook runs `terragrunt validate` on changed stacks and relies on mocks when upstream state is missing.

When adding a new `dependency.*.outputs.*` reference in `inputs`, add the matching key to that dependency's `mock_outputs`.

## Git Hooks

Enable local hooks (blocks direct commits to `main`, auto-formats and re-stages
HCL/TF, validates on push):

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
