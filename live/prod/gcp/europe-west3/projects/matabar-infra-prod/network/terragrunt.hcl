include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/live/prod/gcp/provider.hcl"
}


terraform {
  source = "${get_repo_root()}/modules/gcp/network"
}

dependency "project" {
  config_path = "../project"
}

inputs = {
  project_id = dependency.project.outputs.project_id
  region     = "europe-west3"
}
