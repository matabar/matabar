include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/live/prod/gcp/provider.hcl"
}

# Bootstrap-tier and local-first. The CI service accounts cannot create
# themselves, and CI must not be able to rewrite its own trust policy.
# Apply this unit once with user credentials. State stays on this machine.
remote_state {
  backend = "local"
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# run --all in GitHub Actions skips plan and apply here. A human can still
# run terragrunt apply from this directory.
exclude {
  if      = get_env("CI", "false") == "true"
  actions = ["plan", "apply"]
}

terraform {
  source = "${get_repo_root()}/modules/gcp/github-wif"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

dependency "project" {
  config_path = "../../projects/matabar-prod/project"
  mock_outputs = {
    project_id = "matabar-online-prod"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "tfstate" {
  config_path = "../tfstate"
  mock_outputs = {
    name = "matabar-prod-tfstate"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  project_id        = dependency.project.outputs.project_id
  state_bucket      = dependency.tfstate.outputs.name
  github_repository = "matabar/personal-infra"
  github_owner      = "matabar"

  # DNS roles are added with the DNS unit. This identity starts able to
  # read the project and the state bucket only.
  plan_project_roles  = ["roles/browser"]
  apply_project_roles = ["roles/browser"]
}
