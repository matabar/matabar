include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/live/prod/gcp/provider.hcl"
}


terraform {
  source = "${get_repo_root()}/modules/gcp/network"
}

locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

dependency "project" {
  config_path = "../project"
  mock_outputs = {
    project_id = "mock-project-id"
  }
}

inputs = {
  project_id = dependency.project.outputs.project_id
  region     = local.region_vars.locals.region

  # IAP TCP forwarding range — SSH from anywhere via gcloud IAP tunnel.
  ssh_source_ranges = ["35.235.240.0/20"]

  https_source_ranges = ["0.0.0.0/0"]
}
