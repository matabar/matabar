# personal-infra

GCP foundation for personal projects, managed with OpenTofu and Terragrunt.

This repository creates the GCP project and the remote state bucket. It does not run a virtual machine.

## Directory Structure

- `root.hcl`: Root configuration. Generates the remote state backend (GCS).
- `modules/`: Reusable OpenTofu modules, organized by cloud provider.
  - `modules/gcp/project`: GCP project and API enablement
  - `modules/gcp/storage-bucket`: Versioned GCS bucket (used for Terraform state)
  - `modules/gcp/dns-zone`: Public Cloud DNS zone, DNSSEC, and record sets
  - `modules/gcp/github-wif`: Workload Identity Federation for GitHub Actions
  - `modules/github/repos`: Landing repository, Pages, branch rules, and the production environment
- `live/`: Live infrastructure configurations.
  - `live/terragrunt.hcl`: Global Terragrunt settings
  - `live/prod/env.hcl`: Project id, billing account, and organization parent
  - `live/prod/gcp/provider.hcl`: Generated Google provider block
  - `live/prod/gcp/europe-west3/region.hcl`: Region setting consumed by units
  - `live/prod/gcp/europe-west3/bootstrap/tfstate/`: GCS state bucket (local backend)
  - `live/prod/gcp/europe-west3/projects/matabar-prod/project/`: GCP project (local backend, bootstrap tier)
  - `live/prod/gcp/europe-west3/bootstrap/github-wif/`: GitHub Actions identity (local backend)
  - `live/prod/gcp/europe-west3/projects/matabar-prod/dns/matabar-online/`: `matabar.online` zone
  - `live/prod/github/repos/`: landing repository, Pages, branch rules, production environment

## State Backend

All units store state in the GCS bucket named by `state_bucket` in `live/prod/env.hcl`
(`matabar-prod-tfstate`). `root.hcl` reads that value. The bucket blocks public
access, uses uniform bucket-level access, and keeps object versions.
Two bootstrap-tier units keep their state **local** to avoid a chicken-and-egg
dependency on the bucket:

- `projects/matabar-prod/project` (the project must exist before the bucket)
- `bootstrap/tfstate` (creates the bucket itself)

## Project identity

`live/prod/env.hcl` is the only place that sets the project id and the billing
account. The project module takes `billing_account` as a required input and
does not embed an account id.

The project id is `matabar-online-prod`. If Google says that id is already
taken, change `project_id` in `env.hcl` and apply again. `org_id` and
`folder_id` stay null so the project is created with no organization parent.
Set exactly one of them when the Google account belongs to Cloud Identity or
Workspace.

Linking billing requires `roles/billing.user` on billing account
`01840C-61ACE5-5FE73D`. Creating the project with no organization uses the
identity that owns the Application Default Credentials. Inside an organization,
that identity also needs `roles/resourcemanager.projectCreator`.

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

Do not read outputs from the local-backend units (`project`, `bootstrap/*`). Their state lives only on the machine that applied them, so CI and `init -backend=false` cannot read it. Units take the project id and the state bucket from `live/prod/env.hcl` and list bootstrap units in a `dependencies` block for apply order only.
## GitHub repositories

`live/prod/github/repos` uses the `integrations/github` provider. The token is
the `GITHUB_TOKEN` environment variable. Prefer a GitHub App installation
token. A fine-grained or classic PAT in that variable also works. The token is
not a Terraform variable and is not written to state.

The unit imports `matabar/personal-infra` and creates public
`matabar/matabar.online`. The landing repository is public so GitHub Pages is
free. Pages uses the GitHub Actions build type and the custom domain
`matabar.online`. `pages_https_enforced` is `false` on the first apply. GitHub
will not enforce HTTPS until the certificate is issued, which happens only
after DNS delegates to GitHub. Set `pages_https_enforced = true` and apply
again once `dig matabar.online` answers from GitHub and the Pages certificate
is issued.

Both default branches require a pull request, linear history (squash or
rebase), and reject force pushes. `personal-infra` also requires the status
checks `fmt`, `validate`, `tflint`, `trivy`, and `plan`. The production
environment requires the GitHub user `matabar` to approve a deployment.
`prevent_self_review` is false so the only maintainer can approve an apply
they started. Deployments are limited to the protected default branch.

The landing page content is not in this repository.

App or token permissions: Administration (read and write), Environments
(read and write), Pages (read and write), Contents (read), Metadata (read),
and Repository creation (read and write). A classic PAT needs the `repo` scope.

## DNS

`dns/matabar-online` publishes a public zone for `matabar.online` with DNSSEC
(ECDSA P-256, NSEC3). Record sets are a map on the live unit. The zone starts
with no records other than the NS and SOA that Cloud DNS creates itself.

`enable_email_forwarding` is `false`. Set it to `true` to publish ImprovMX MX
records (`10 mx1.improvmx.com.`, `20 mx2.improvmx.com.`) and SPF
`v=spf1 include:spf.improvmx.com ~all`. That flag does not create an ImprovMX
account; aliases are configured there. Namecheap email forwarding stops working
once the domain's name servers leave Namecheap. Leave the flag off until a
forwarder is chosen.

The project unit enables `dns.googleapis.com`. The plan service account gets
`roles/dns.reader` and the apply service account gets `roles/dns.admin`.

## GitHub Actions identity

`bootstrap/github-wif` is a bootstrap-tier unit with **local** state. Apply it
with your user credentials after the project and the state bucket. It creates
a Workload Identity pool and two service accounts:

- `github-tf-plan` can read the project and the state bucket. Pull-request
  plans use it and do not lock state.
- `github-tf-apply` can write state and lock it. Only a token minted for
  `refs/heads/main` in the `production` GitHub environment can impersonate it.

CI never plans or applies this unit. There are no JSON service-account keys.
After apply, copy the outputs into GitHub repository variables
`WIF_PLAN_PROVIDER`, `WIF_PLAN_SERVICE_ACCOUNT`, `WIF_APPLY_PROVIDER`, and
`WIF_APPLY_SERVICE_ACCOUNT`.

Back up `bootstrap/github-wif/terraform.tfstate`. It is gitignored. Losing it
means importing the pool and service accounts.

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
