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
  source = "${get_repo_root()}/modules/github/repos"
}

dependency "tfstate" {
  config_path = "../../gcp/europe-west3/bootstrap/tfstate"
  mock_outputs = {
    name = "matabar-prod-tfstate"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  # Makes Terragrunt apply the state bucket before this unit.
  state_bucket                   = dependency.tfstate.outputs.name
  infra_repository_name          = "personal-infra"
  infra_repository_description   = "GCP foundation and DNS for matabar.online"
  landing_repository_name        = local.env.domain
  landing_repository_description = "Static landing page for matabar.online"
  pages_domain                   = local.env.domain
  pages_https_enforced           = false
  reviewer_username              = local.env.github_owner
  infra_required_checks          = ["fmt", "validate", "tflint", "trivy", "plan"]
}
