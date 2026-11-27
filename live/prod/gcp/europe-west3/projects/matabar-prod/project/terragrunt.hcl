include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/live/prod/gcp/provider.hcl"
}

# Bootstrap-tier: the project must exist before the GCS state bucket, so this
# unit keeps its state local rather than in the (not-yet-existing) bucket.
# Apply it on a machine with user Application Default Credentials. CI does not
# apply this unit.
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

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/modules/gcp/project"
}

inputs = {
  name            = local.env.project_name
  project_id      = local.env.project_id
  billing_account = local.env.billing_account
  org_id          = local.env.org_id
  folder_id       = local.env.folder_id
  enabled_services = [
    "storage.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "dns.googleapis.com",
  ]
}
