include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/infra/live/prod/gcp/provider.hcl"
}

# Bootstrap-tier: this unit creates the bucket that backs remote state, so it
# keeps its own state local. Apply it with user credentials after the project
# unit. CI does not apply this unit.
exclude {
  if      = get_env("CI", "false") == "true"
  actions = ["plan", "apply"]
}
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
  source = "${get_repo_root()}/infra/modules/gcp/storage-bucket"
}

locals {
  env         = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

# Ordering only. The project unit keeps local state, so its outputs are not
# readable in CI or on a fresh clone. The project id comes from env.hcl.
dependencies {
  paths = ["../../projects/matabar-prod/project"]
}

inputs = {
  name       = local.env.state_bucket
  project_id = local.env.project_id
  location   = local.region_vars.locals.region
}
