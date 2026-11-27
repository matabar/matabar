variable "repository_name" {
  type        = string
  description = "Existing monorepo to import and protect. Example: matabar."
}

variable "repository_description" {
  type        = string
  description = "Description set on the repository."
}

variable "pages_domain" {
  type        = string
  description = "Custom domain for GitHub Pages. Example: matabar.online."
}

variable "pages_https_enforced" {
  type        = bool
  description = "Enforce HTTPS on the custom domain. Leave false until GitHub has issued the certificate, then apply again."
  default     = false
}

variable "reviewer_username" {
  type        = string
  description = "GitHub user required to approve deployments to the production environment."
}

variable "production_environment" {
  type        = string
  description = "Environment that gates apply workflows."
  default     = "production"
}

variable "required_checks" {
  type        = list(string)
  description = "Status check contexts required before merging to the default branch."
  default     = ["ci"]
}
