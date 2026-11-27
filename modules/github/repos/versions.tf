terraform {
  required_version = ">= 1.13.10, < 1.14.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
  }
}
