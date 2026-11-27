variable "project_id" {
  type        = string
  description = "GCP project that owns the pool and the CI service accounts."
}

variable "state_bucket" {
  type        = string
  description = "Terraform state bucket. Plan gets read access; apply gets object admin."
}

variable "github_repository" {
  type        = string
  description = "GitHub repository allowed to federate, as owner/name."
}

variable "github_owner" {
  type        = string
  description = "GitHub user or organization that owns github_repository."
}

variable "pool_id" {
  type        = string
  description = "Workload Identity pool id."
  default     = "github-actions"
}

variable "plan_provider_id" {
  type        = string
  description = "Workload Identity provider id used by pull-request plans."
  default     = "github-plan"
}

variable "apply_provider_id" {
  type        = string
  description = "Workload Identity provider id used by the production apply."
  default     = "github-apply"
}

variable "plan_service_account_id" {
  type        = string
  description = "Account id for the read-only plan service account."
  default     = "github-tf-plan"
}

variable "apply_service_account_id" {
  type        = string
  description = "Account id for the apply service account."
  default     = "github-tf-apply"
}

variable "plan_project_roles" {
  type        = list(string)
  description = "Project roles granted to the plan service account. Keep this read-only."
  default     = ["roles/browser"]
}

variable "apply_project_roles" {
  type        = list(string)
  description = "Project roles granted to the apply service account."
  default     = ["roles/browser"]
}

variable "production_environment" {
  type        = string
  description = "GitHub environment name that gates apply. The apply provider requires this claim."
  default     = "production"
}
