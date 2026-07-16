# personal-infra

Infrastructure management for personal projects using OpenTofu and Terragrunt.

## Directory Structure

- `root.hcl`: Root configuration. Generates the remote state backend (GCS).
- `modules/`: Reusable OpenTofu modules, organized by cloud provider.
  - `modules/gcp/project`: GCP project and API enablement
  - `modules/gcp/network`: VPC, subnetwork, and firewall rules
  - `modules/gcp/compute-instance`: Compute instance (static IP, IAP SSH, cloud-init web stack)
  - `modules/gcp/storage-bucket`: Versioned GCS bucket (used for Terraform state)
- `live/`: Live infrastructure configurations.
  - `live/terragrunt.hcl`: Global Terragrunt settings
  - `live/prod/gcp/provider.hcl`: Generated Google provider block
  - `live/prod/gcp/europe-west3/region.hcl`: Region setting consumed by units
  - `live/prod/gcp/europe-west3/bootstrap/tfstate/`: GCS state bucket (local backend)
  - `live/prod/gcp/europe-west3/projects/matabar-prod/`: Prod GCP project stack
    - `project/`: GCP project (local backend, bootstrap tier)
    - `network/`: VPC, subnet, firewall
    - `workloads/compute-instance/matabar-prod/`: Compute VM with Docker + nginx

## State Backend

All units store state in the GCS bucket `matabar-prod-tfstate` (configured in `root.hcl`).
Two bootstrap-tier units keep their state **local** to avoid a chicken-and-egg
dependency on the bucket:

- `projects/matabar-prod/project` (the project must exist before the bucket)
- `bootstrap/tfstate` (creates the bucket itself)

## Secrets (`.env`)

Secrets live in a **project-root** `.env` file (git-ignored). Do not put them in `~/.zshrc` or commit them.

```bash
cp .env.example .env
# edit .env — set TF_VAR_duckdns_token (see below)

set -a && source .env && set +a
```

| Variable | Purpose |
|----------|---------|
| `TF_VAR_duckdns_token` | DuckDNS API token (required for compute apply) |
| `TF_VAR_certbot_email` | Let's Encrypt email (optional; defaults in live config) |

SSH private key stays at `~/.ssh/matabar-prod` (not in this repo).

### Where to get the DuckDNS token

1. Sign in at [duckdns.org](https://www.duckdns.org) (same account that owns `matabar.duckdns.org`).
2. Open [duckdns.org/domains](https://www.duckdns.org/domains).
3. At the **top of the page**, find the **token** field in your account summary (a UUID).
4. Paste it into `.env` as `TF_VAR_duckdns_token=...`.

To rotate the token, use the **recreate token** option on the same page, then update `.env`.

## Apply Order

Stacks have Terragrunt dependencies. From the **repo root**, load `.env` then apply in order:

```bash
set -a && source .env && set +a

# 1. Project (local backend)
cd live/prod/gcp/europe-west3/projects/matabar-prod/project
terragrunt apply

# 2. State bucket (local backend)
cd ../../../bootstrap/tfstate
terragrunt apply

# 3. Network (GCS backend)
cd ../../projects/matabar-prod/network
terragrunt apply

# 4. Compute instance (GCS backend)
cd ../workloads/compute-instance/matabar-prod
terragrunt apply
terragrunt output external_ip
```

The compute module bootstraps the VM on **first boot** via cloud-init:

- Docker + docker-compose (placeholder `whoami` on `127.0.0.1:8080`)
- Host nginx reverse proxy on ports 80/443
- certbot Let's Encrypt with HTTP→HTTPS redirect
- DuckDNS A record synced by Terraform when the static IP is created

### One-time DuckDNS setup

1. Register at [duckdns.org](https://www.duckdns.org) and create subdomain `matabar`.
2. Apply the compute stack with `TF_VAR_duckdns_token` set — Terraform updates the A record.

### Verify

```bash
curl -I http://matabar.duckdns.org    # 301 to HTTPS
curl -I https://matabar.duckdns.org   # 200, valid cert
```

### Existing VM caveat

cloud-init runs on first boot only. To re-run bootstrap after changing templates, replace the instance (e.g. `terragrunt taint` the VM resource) or configure manually over SSH.

## SSH Access (IAP)

SSH is **not** open to the public internet. Port 22 accepts connections only from
the GCP IAP range (`35.235.240.0/20`). Access requires:

- Google IAM role `roles/iap.tunnelResourceAccessor` (granted via `TF_VAR_iap_user_email`)
- SSH key at `~/.ssh/matabar-prod` (pushed via instance metadata)

Add to `~/.ssh/config` on your local machine:

```
Host matabar-prod
  HostName matabar-prod
  User matan
  IdentityFile ~/.ssh/matabar-prod
  ProxyCommand gcloud compute start-iap-tunnel %h %p --listen-on-stdin --project=matabar-prod-294f --zone=europe-west3-a --verbosity=warning
```

Prerequisites: `gcloud auth login` and Application Default Credentials.

```bash
ssh matabar-prod
```

VS Code Remote-SSH uses the same `~/.ssh/config` entry.

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
