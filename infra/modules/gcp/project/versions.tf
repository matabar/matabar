terraform {
  required_version = ">= 1.13.10, < 1.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.12.0"
    }
  }
}
