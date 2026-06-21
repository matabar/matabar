generate "databricks_provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.118"
    }
  }
}

variable "databricks_profile" {
  type    = string
  default = "matabar"
}

provider "databricks" {
  auth_type = "databricks-cli"
  profile   = var.databricks_profile
  # Reads cached OAuth tokens from ~/.databrickscfg for the profile above.
  # Authenticate first: databricks auth login --profile matabar
}
EOF
}
