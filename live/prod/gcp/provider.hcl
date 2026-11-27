generate "gcp_provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "gcp_region" {
  type        = string
  description = "Region passed to the Google provider. Individual resources may still be global."
  default     = "europe-west3"
}

provider "google" {
  region = var.gcp_region
}
EOF
}
