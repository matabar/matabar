include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/live/prod/gcp/provider.hcl"
}

terraform {
  source = "${get_repo_root()}/modules/gcp/vm"
}

locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

dependency "project" {
  config_path = "../../project"
}

dependency "network" {
  config_path = "../../network"
  mock_outputs = {
    network_id    = "mock-network-id"
    subnetwork_id = "mock-subnet-id"
  }
}

inputs = {
  hostname     = "prod-vm-01"
  project_id   = dependency.project.outputs.project_id
  zone         = "${local.region_vars.locals.region}-a"
  machine_type = "e2-medium"
  network      = dependency.network.outputs.network_id
  subnetwork   = dependency.network.outputs.subnetwork_id
}
