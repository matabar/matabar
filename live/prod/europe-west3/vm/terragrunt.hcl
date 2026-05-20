include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  root_vars = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  env_vars  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../modules/gcp-vm"
}

dependency "project" {
  config_path = "../project"

  mock_outputs = {
    project_id = "mock-project-id"
  }
}

inputs = {
  name       = "prod-vm-01"
  project_id = dependency.project.outputs.project_id
  zone       = "${local.root_vars.locals.region}-a"
}
