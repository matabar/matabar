include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/live/prod/gcp/provider.hcl"
}

# Bootstrap-tier: the project must exist before the GCS state bucket, so this
# unit keeps its state local rather than in the (not-yet-existing) bucket.
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
  source = "${get_repo_root()}/modules/gcp/project"
}

inputs = {
  name             = "matabar-prod"
  project_id       = "matabar-prod-294f"
  billing_account  = "01840C-61ACE5-5FE73D"
  org_id           = null
  folder_id        = null
  enabled_services = []
}
