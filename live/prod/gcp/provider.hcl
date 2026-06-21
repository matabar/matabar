generate "gcp_provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "gcp_region" {
  type    = string
  default = "europe-west3"
}

provider "google" {
  region = var.gcp_region
}

provider "google-beta" {
  region = var.gcp_region
}
EOF
}
