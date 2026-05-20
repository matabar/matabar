locals {
  billing_account = "01840C-61ACE5-5FE73D"
  region          = "europe-west3"
}

# Generate a Google provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "google" {
  region = "${local.region}"
}

provider "google-beta" {
  region = "${local.region}"
}
EOF
}

# Remote state configuration (Local for now, easily migratable to GCS)
remote_state {
  backend = "local"
  config = {
    path = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
