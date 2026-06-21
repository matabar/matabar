# personal-infra

Infrastructure management for personal projects using OpenTofu and Terragrunt.

## Directory Structure

- `root.hcl`: Root configuration. Generates the remote state backend (GCS).
- `modules/`: Reusable OpenTofu modules, organized by cloud provider.
  - `modules/gcp/project`: GCP project and API enablement
  - `modules/gcp/network`: VPC, subnetwork, and firewall rules
  - `modules/gcp/vm`: Compute instance (service account, optional static IP, SSH metadata)
  - `modules/gcp/gcs-bucket`: Versioned GCS bucket (used for Terraform state)
  - `modules/databricks/lakebase`: Lakebase Autoscaling project, branch, endpoint, role, database
- `live/`: Live infrastructure configurations.
  - `live/terragrunt.hcl`: Global Terragrunt settings
  - `live/prod/databricks/provider.hcl`: Generated Databricks provider block
  - `live/prod/databricks/workloads/lakebase/matabar-prod/`: Lakebase production database
  - `live/prod/gcp/provider.hcl`: Generated Google provider block
  - `live/prod/gcp/europe-west3/region.hcl`: Region setting consumed by units
  - `live/prod/gcp/europe-west3/bootstrap/tfstate/`: GCS state bucket (local backend)
  - `live/prod/gcp/europe-west3/projects/matabar-prod/`: Prod GCP project stack
    - `project/`: GCP project (local backend, bootstrap tier)
    - `network/`: VPC, subnet, firewall
    - `workloads/prod-vm-01/`: Compute VM

## State Backend

All units store state in the GCS bucket `matabar-prod-tfstate` (configured in `root.hcl`).
Two bootstrap-tier units keep their state **local** to avoid a chicken-and-egg
dependency on the bucket:

- `projects/matabar-prod/project` (the project must exist before the bucket)
- `bootstrap/tfstate` (creates the bucket itself)

## Apply Order

Stacks have Terragrunt dependencies. Apply in this order:

```bash
# 1. Project (local backend)
cd live/prod/gcp/europe-west3/projects/matabar-prod/project
terragrunt apply

# 2. State bucket (local backend)
cd ../../../bootstrap/tfstate
terragrunt apply

# 3. Network (GCS backend) — creates the SSH firewall rule
cd ../../projects/matabar-prod/network
terragrunt apply

# 4. VM (GCS backend) — outputs the static external IP
cd ../workloads/prod-vm-01
terragrunt apply
terragrunt output external_ip
```

## Databricks Lakebase

Lakebase Autoscaling is managed via the `databricks/databricks` provider. Authentication
uses the **Databricks CLI** profile stored in `~/.databrickscfg` — credentials are
never committed to this repository.

### Prerequisites (one-time)

1. [Install the Databricks CLI](https://docs.databricks.com/dev-tools/cli/install.html).
2. Log in to your workspace and create a profile (e.g. `matabar`):

```bash
databricks auth login --profile matabar
```

3. Verify the profile works:

```bash
databricks auth profiles --profile matabar
databricks current-user me --profile matabar
```

Your user needs permission to create Lakebase projects (typically **Admin** on the
workspace for the initial apply). After the project is created, ensure your account
retains **CAN MANAGE** on the Lakebase project for ongoing Terraform updates.

To use a different profile name, set `TF_VAR_databricks_profile=<name>` or override
`DATABRICKS_CONFIG_PROFILE` before running Terragrunt.

> OpenTofu with the Databricks provider is supported but considered experimental
> by Databricks. Pin the provider version and run `terragrunt plan` before apply.

### Apply

```bash
cd live/prod/databricks/workloads/lakebase/matabar-prod
terragrunt init
terragrunt plan
terragrunt apply
terragrunt output
```

The stack is independent of GCP — no Terragrunt dependencies on GCP units.

## SSH Access

- A dedicated key lives at `~/.ssh/matabar-prod`; its public key is pushed
  to the VM via instance metadata for user `matan`.
- SSH is firewalled to a single source IP, configured in
  `network/terragrunt.hcl` as `ssh_source_ranges`. This is a **dynamic ISP
  address** — update it whenever your public IP changes.
- After applying the VM, set the host in `~/.ssh/config`:

```bash
ip=$(cd live/prod/gcp/europe-west3/projects/matabar-prod/workloads/prod-vm-01 && terragrunt output -raw external_ip)
# update the HostName for `Host prod-vm-01` in ~/.ssh/config to $ip
ssh prod-vm-01
```

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
- **Phased Planning**: Every non-trivial task requires a phased plan.
- **Conventional Commits**: Strict adherence to commit message standards.
