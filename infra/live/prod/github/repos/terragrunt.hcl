include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

# Token comes from GITHUB_TOKEN in the environment (a GitHub App installation
# token or a PAT). It is not a Terraform variable, so it is not stored in state.
generate "github_provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "github" {
      owner = "${local.env.github_owner}"
    }
  EOF
}

terraform {
  source = "${get_repo_root()}/infra/modules/github/repos"
}

# Ordering only. Bootstrap units keep local state, so their outputs are not
# readable in CI or on a fresh clone. Shared values come from env.hcl.
dependencies {
  paths = [
    "../../gcp/europe-west3/bootstrap/tfstate",
  ]
}

inputs = {
  repository_name        = "matabar"
  repository_description = "Monorepo: GCP foundation, DNS, GitHub config and the matabar.online site"
  pages_domain           = local.env.domain
  pages_https_enforced   = true
  reviewer_username      = local.env.github_owner
  required_checks        = ["ci"]
}
