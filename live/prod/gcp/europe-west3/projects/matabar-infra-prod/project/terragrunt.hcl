include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/live/prod/gcp/provider.hcl"
}


terraform {
  source = "${get_repo_root()}/modules/gcp/project"
}

inputs = {
  name             = "matabar-infra-prod"
  project_id       = "matabar-infra-prod-7742"
  billing_account  = "01840C-61ACE5-5FE73D"
  org_id           = null
  folder_id        = null
  enabled_services = ["compute.googleapis.com"]
  region           = "europe-west3"
}
