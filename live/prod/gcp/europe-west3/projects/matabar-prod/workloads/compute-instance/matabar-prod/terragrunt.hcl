include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/live/prod/gcp/provider.hcl"
}

terraform {
  source = "${get_repo_root()}/modules/gcp/compute-instance"
}

locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  owner_email = "owner@example.com"
}

dependency "project" {
  config_path = "../../../project"
  mock_outputs = {
    project_id = "mock-project-id"
  }
}

dependency "network" {
  config_path = "../../../network"
  mock_outputs = {
    network_id    = "mock-network-id"
    subnetwork_id = "mock-subnet-id"
  }
}

inputs = {
  hostname     = "matabar-prod"
  project_id   = dependency.project.outputs.project_id
  region       = local.region_vars.locals.region
  zone         = "${local.region_vars.locals.region}-a"
  machine_type = "e2-medium"
  network      = dependency.network.outputs.network_id
  subnetwork   = dependency.network.outputs.subnetwork_id

  enable_external_ip = true
  ssh_user           = "matan"
  ssh_pubkey         = trimspace(file("${get_env("HOME")}/.ssh/matabar-prod.pub"))
  tags               = ["ssh", "https"]
  labels = {
    environment = "prod"
    managed_by  = "terragrunt"
  }

  iap_tunnel_members = ["user:${local.owner_email}"]

  enable_web_stack  = true
  duckdns_subdomain = "matabar"
  web_domain        = "matabar.duckdns.org"
  certbot_email     = get_env("TF_VAR_certbot_email", local.owner_email)
  duckdns_token     = get_env("TF_VAR_duckdns_token", "")
  app_upstream_port = 8080
}
