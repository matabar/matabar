locals {
  env_config   = read_terragrunt_config("${get_repo_root()}/live/prod/env.hcl")
  state_bucket = local.env_config.locals.state_bucket
}

# Remote state in GCS for every unit that is not bootstrap-tier.
# The project and the state bucket override this back to a local backend:
# the bucket cannot store state until it exists.
remote_state {
  backend = "gcs"
  config = {
    bucket = local.state_bucket
    prefix = path_relative_to_include()
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
