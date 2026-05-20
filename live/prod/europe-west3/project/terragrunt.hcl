include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  root_vars = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  env_vars  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../modules/gcp-project"
}

inputs = {
  name            = "personal-infra-prod"
  project_id      = "matabar-infra-prod-7742"
  billing_account = local.root_vars.locals.billing_account
}
