locals {
  state_bucket = "matabar-prod-tfstate"
}

# Remote state in GCS for all units. Bootstrap-tier units (the project and
# the state bucket itself) override this back to a local backend to avoid the
# chicken-and-egg problem of needing the bucket before it exists.
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
