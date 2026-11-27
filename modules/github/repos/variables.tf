variable "infra_repository_name" {
  type        = string
  description = "Existing repository to import and protect. Example: personal-infra."
}

variable "infra_repository_description" {
  type        = string
  description = "Description set on the infrastructure repository."
}

variable "landing_repository_name" {
  type        = string
  description = "Public repository that hosts the landing page. Example: matabar.online."
}

variable "landing_repository_description" {
  type        = string
  description = "Description set on the landing repository."
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

variable "infra_required_checks" {
  type        = list(string)
  description = "Status check contexts required before merging to the infrastructure default branch."
  default     = ["fmt", "validate", "tflint", "trivy", "plan / terragrunt"]
}
