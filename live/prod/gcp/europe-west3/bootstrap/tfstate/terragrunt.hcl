include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/live/prod/gcp/provider.hcl"
}

# Bootstrap-tier: this unit creates the very bucket that backs remote state,
# so it must keep its own state local.
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

terraform {
  source = "${get_repo_root()}/modules/gcp/storage-bucket"
}

locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

dependency "project" {
  config_path = "../../projects/matabar-prod/project"
  mock_outputs = {
    project_id = "matabar-prod-294f"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  name       = "matabar-prod-tfstate"
  project_id = dependency.project.outputs.project_id
  location   = local.region_vars.locals.region
}
