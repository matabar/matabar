include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/infra/live/prod/gcp/provider.hcl"
}

# Bootstrap-tier and local-first. The CI service accounts cannot create
# themselves, and CI must not be able to rewrite its own trust policy.
# Apply this unit once with user credentials. State stays on this machine.
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

# run --all in GitHub Actions skips plan and apply here. A human can still
# run terragrunt apply from this directory.
exclude {
  if      = get_env("CI", "false") == "true"
  actions = ["plan", "apply"]
}

terraform {
  source = "${get_repo_root()}/infra/modules/gcp/github-wif"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

# Ordering only. Bootstrap units keep local state, so their outputs are not
# readable in CI or on a fresh clone. Shared values come from env.hcl.
dependencies {
  paths = [
    "../../projects/matabar-prod/project",
    "../tfstate",
  ]
}

inputs = {
  project_id        = local.env.project_id
  state_bucket      = local.env.state_bucket
  github_repository = "matabar/matabar"
  github_owner      = "matabar"

  plan_project_roles = [
    "roles/browser",
    "roles/dns.reader",
  ]
  apply_project_roles = [
    "roles/browser",
    "roles/dns.admin",
  ]
}
