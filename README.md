# personal-infra

GCP foundation for personal projects, managed with OpenTofu and Terragrunt.

This repository creates the GCP project, the remote state bucket, Cloud DNS for
`matabar.online`, and the GitHub repository that serves the landing page. It
does not run a virtual machine. The landing page content lives in
`matabar/matabar.online`, not here.

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

## Bootstrap and cutover

Nothing in this repository has been applied. Merge this stack before the first
apply. Branch protection is not active until the GitHub unit is applied, so
the merge is not blocked by the new required checks. The deploy workflow on
`main` fails until the steps below are done; re-run it at the end.

Install OpenTofu 1.13.10, Terragrunt 1.2.3, TFLint 0.66.0, and Trivy 0.76.2
(`mise install` reads `.tool-versions`). Then:

```bash
git config core.hooksPath .githooks
gcloud auth login
gcloud auth application-default login
```

Do not set an Application Default Credentials quota project until some project
exists. If project creation fails because an API has no quota project, and you
already have a different GCP project, run
`gcloud auth application-default set-quota-project EXISTING_PROJECT_ID` and
apply again.

`org_id` and `folder_id` in `live/prod/env.hcl` are null, so the project is
created with no organization parent. That matches a personal Google account.
If the account is inside Cloud Identity or Workspace and the organization
forbids parentless projects, set exactly one of `org_id` or `folder_id`.
Inside an organization the identity also needs
`roles/resourcemanager.projectCreator`. Linking billing needs
`roles/billing.user` on `01840C-61ACE5-5FE73D`. Billing Account Administrator
is not required. If Google says `matabar-online-prod` is taken, change
`project_id` in `env.hcl` only.

From the repo root, with user credentials (not Workload Identity):

```bash
terragrunt --working-dir live/prod/gcp/europe-west3/projects/matabar-prod/project apply
terragrunt --working-dir live/prod/gcp/europe-west3/bootstrap/tfstate apply
terragrunt --working-dir live/prod/gcp/europe-west3/bootstrap/github-wif apply
```

The first three units keep **local** state. Back up these gitignored files:

- `live/prod/gcp/europe-west3/projects/matabar-prod/project/terraform.tfstate`
- `live/prod/gcp/europe-west3/bootstrap/tfstate/terraform.tfstate`
- `live/prod/gcp/europe-west3/bootstrap/github-wif/terraform.tfstate`

Copy the `github-wif` outputs into repository variables on `matabar/personal-infra`:

| Variable | Output |
| --- | --- |
| `WIF_PLAN_PROVIDER` | `plan_workload_identity_provider` |
| `WIF_PLAN_SERVICE_ACCOUNT` | `plan_service_account` |
| `WIF_APPLY_PROVIDER` | `apply_workload_identity_provider` |
| `WIF_APPLY_SERVICE_ACCOUNT` | `apply_service_account` |

Create a GitHub App (preferred) or a PAT before the GitHub unit. This
repository cannot create that credential. Install the app on the user account
`matabar` for all repositories, with Administration, Environments, Pages,
Contents (read), Metadata (read), Vulnerability alerts, and Repository
creation. Mint an installation token, or use a classic PAT with the `repo`
scope, and export it only for the local apply:

```bash
export GITHUB_TOKEN=...   # not a TF_VAR; it is not written to state
terragrunt --working-dir live/prod/github/repos apply
```

For later CI applies, store the same credential as secrets, not in git:

| Secret | Purpose |
| --- | --- |
| `GH_APP_ID` | GitHub App id |
| `GH_APP_INSTALLATION_ID` | Installation id |
| `GH_APP_PRIVATE_KEY` | App private key PEM |
| `GH_ADMIN_TOKEN` | Classic or fine-grained PAT, used only when the app secrets are unset |

The GitHub unit imports `personal-infra`, creates public `matabar/matabar.online`,
turns on Actions-based Pages for `matabar.online`, protects `main`, and creates
the `production` environment with `matabar` as the required reviewer.
`pages_https_enforced` stays false on this first apply.

Then publish the zone:

```bash
terragrunt --working-dir live/prod/gcp/europe-west3/projects/matabar-prod/dns/matabar-online apply
terragrunt --working-dir live/prod/gcp/europe-west3/projects/matabar-prod/dns/matabar-online output name_servers
```

In Namecheap, open the domain, set Nameservers to **Custom DNS**, and enter
the name servers from that output. This is manual. Switching nameservers turns
off Namecheap BasicDNS, including the leftover email forwarding
(`eforward1-5.registrar-servers.com` and
`v=spf1 include:spf.efwd.registrar-servers.com ~all`). Mail for the domain
stops until `enable_email_forwarding` is set and an ImprovMX account exists.
ImprovMX is not created by Terraform.

Confirm the delegation before any DS record:

```bash
dig NS matabar.online @1.1.1.1
dig NS matabar.online @8.8.8.8
dig SOA matabar.online @1.1.1.1
```

The NS answers should be the Google name servers. Then:

```bash
terragrunt --working-dir live/prod/gcp/europe-west3/projects/matabar-prod/dns/matabar-online output dnssec_ds_records
```

At Namecheap, add one DS record using the `sha256` digest: key tag, algorithm
**13** (`ecdsap256sha256`), digest type **2**, and the digest. Add the DS only
after the Google name servers answer. A DS published while Namecheap is still
authoritative makes validating resolvers treat the domain as bogus.

After the Pages custom domain exists, GitHub shows a TXT value for
`_github-pages-challenge-matabar`. Export it and set the same repository
variable so a later CI apply does not delete the record:

```bash
export GITHUB_PAGES_CHALLENGE='the-value-from-github'
terragrunt --working-dir live/prod/gcp/europe-west3/projects/matabar-prod/dns/matabar-online apply
```

When GitHub reports the Pages certificate as issued, set
`pages_https_enforced = true` in `live/prod/github/repos/terragrunt.hcl` and
apply that unit again. The first apply cannot enforce HTTPS; GitHub rejects
it until the certificate exists.

Check DNSSEC with `dig +dnssec SOA matabar.online @1.1.1.1` and
[dnsviz.net](https://dnsviz.net). Re-run the failed Deploy workflow and approve
it in the `production` environment.

### What cannot be done in this repository

- `gcloud auth login` and Application Default Credentials
- Granting `roles/billing.user` on the billing account
- Choosing an organization or folder parent, if the Google account requires one
- Creating the GitHub App or PAT, and storing its secret in GitHub
- The Namecheap nameserver change
- The Namecheap DS record
- The Pages verification string, until GitHub displays it
- Approving the `production` deployment
- The second apply that turns on HTTPS, after the certificate is issued
- An ImprovMX account, if email forwarding is wanted
- The landing page files, which belong in `matabar/matabar.online`

### Terragrunt dependencies

Downstream stacks reference upstream outputs via `dependency` blocks. Each dependency defines `mock_outputs` — placeholder values Terragrunt substitutes when upstream state is unavailable. Mocks are used only for `init`, `validate`, and `plan` (via `mock_outputs_allowed_terraform_commands`); `apply` always requires real upstream outputs.

This lets you run `terragrunt validate` or `plan` on a stack before its dependencies are applied (e.g. on a fresh clone). The pre-push hook runs `terragrunt validate` on changed stacks and relies on mocks when upstream state is missing.

When adding a new `dependency.*.outputs.*` reference in `inputs`, add the matching key to that dependency's `mock_outputs`.

Do not read outputs from the local-backend units (`project`, `bootstrap/*`). Their state lives only on the machine that applied them, so CI and `init -backend=false` cannot read it. Units take the project id and the state bucket from `live/prod/env.hcl` and list bootstrap units in a `dependencies` block for apply order only.
## GitHub repositories

`live/prod/github/repos` uses the `integrations/github` provider. The token is
the `GITHUB_TOKEN` environment variable. Use a fine-grained PAT owned by
`matabar`: a GitHub App installation token cannot create a repository under a
personal account, so it can manage `matabar.online` only after it exists. The
token is not a Terraform variable and is not written to state.

The unit imports `matabar/personal-infra` (public, so rulesets and environment
reviewers work on GitHub Free) and creates public
`matabar/matabar.online`. The landing repository is public so GitHub Pages is
free. Pages uses the GitHub Actions build type and the custom domain
`matabar.online`. `pages_https_enforced` is `false` on the first apply. GitHub
will not enforce HTTPS until the certificate is issued, which happens only
after DNS delegates to GitHub. Set `pages_https_enforced = true` and apply
again once `dig matabar.online` answers from GitHub and the Pages certificate
is issued.

Both default branches require a pull request, linear history (squash or
rebase), and reject force pushes. `personal-infra` also requires the status
checks `fmt`, `validate`, `tflint`, `trivy`, and `plan / terragrunt` (the
plan job calls a reusable workflow, so GitHub names its check
`<caller job> / <called job>`). The production
environment requires the GitHub user `matabar` to approve a deployment.
`prevent_self_review` is false so the only maintainer can approve an apply
they started. Deployments are limited to the protected default branch.

The landing page content is not in this repository.

Fine-grained PAT: resource owner `matabar`, **All repositories**, with
repository permissions Administration (read and write), Environments (read and
write), Pages (read and write), Contents (read and write, needed for
`auto_init`), and Metadata (read). Administration write on all repositories is
what lets the token create `matabar.online` and turn on vulnerability alerts.

## DNS

`dns/matabar-online` publishes a public zone for `matabar.online` with DNSSEC
(ECDSA P-256, NSEC3). The record map points the apex at the four GitHub Pages
A and AAAA addresses and points `www` at `matabar.github.io.`.

The `_github-pages-challenge-matabar` TXT record is omitted until
`PAGES_CHALLENGE` is set to the value GitHub shows after the custom
domain is saved. Set the same value as a GitHub repository variable before CI
applies the zone, or a later apply will not keep the record.

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

## Pull request checks

Every pull request, and every push that is not to `main`, runs `fmt`,
`validate`, `tflint`, `trivy`, and `plan`. Validate uses `-backend=false` and
the committed provider lock. `plan` uses Workload Identity and does not lock
state. It plans only units changed since the pull request base (or `main` on a
branch push), plus units that depend on them, and posts the log on the pull
request. The project, state bucket, and GitHub identity units exclude
themselves from CI plan and apply.

Tool versions are pinned in `.tool-versions`. The `plan` check stays red until
the `WIF_PLAN_PROVIDER` and `WIF_PLAN_SERVICE_ACCOUNT` repository variables
exist.

A push to `main` runs Deploy. The `plan` job plans the units changed since
the previous `main` commit (`github.event.before`) with the read-only
identity, so the plan is in the run before anyone approves. When it has
changes, the `apply` job runs in the `production` environment, waits for the
required reviewer, locks remote state, and applies the same units with
`WIF_APPLY_PROVIDER` and `WIF_APPLY_SERVICE_ACCOUNT`. A plan with no changes
skips the apply. A manual run from the Actions tab (`workflow_dispatch`) plans
every unit. The concurrency group `production-apply` does not cancel an
apply that is already running.

A daily plan, also available from the Actions tab, plans every CI-managed
unit. Drift opens or updates an issue titled `Drift detected in personal-infra`
and closes it when the next clean plan runs. Dependabot proposes weekly
updates for GitHub Actions and the pinned providers. `CODEOWNERS` requests
review from `@matabar`.

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
