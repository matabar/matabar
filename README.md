# personal-infra

Infrastructure management for personal projects using OpenTofu and Terragrunt.

## Directory Structure

- `root.hcl`: Root configuration for providers and remote state.
- `modules/`: Reusable OpenTofu modules, organized by cloud provider.
  - `modules/gcp/project`: GCP project and API enablement
  - `modules/gcp/network`: VPC and subnetwork
  - `modules/gcp/vm`: Compute instance
- `live/`: Live infrastructure configurations.
  - `live/terragrunt.hcl`: Global Terragrunt settings
  - `live/prod/gcp/europe-west3/projects/personal-infra-prod/`: Prod GCP project stack
    - `project/`: GCP project
    - `network/`: VPC and subnet
    - `workloads/prod-vm-01/`: Compute VM

## Apply Order

Stacks have Terragrunt dependencies — apply in this order:

```bash
cd live/prod/gcp/europe-west3/projects/personal-infra-prod/project
terragrunt apply

cd ../network
terragrunt apply

cd ../workloads/prod-vm-01
terragrunt apply
```

## Git Hooks

Enable local hooks (blocks direct commits to `main`, auto-formats HCL/TF, validates on push):

```bash
git config core.hooksPath .githooks
```

## AI Agent Conventions

This repository follows strict conventions for AI agents as defined in [AGENTS.md](./AGENTS.md).

**Key Rules:**

- **No Direct Commits to Main**: All work must be performed in feature branches.
- **Phased Planning**: Every non-trivial task requires a phased plan.
- **Conventional Commits**: Strict adherence to commit message standards.
