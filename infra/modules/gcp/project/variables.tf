variable "name" {
  type        = string
  description = "Display name of the GCP project."
}

variable "project_id" {
  type        = string
  description = "Globally unique GCP project id. Immutable after creation."
}

variable "billing_account" {
  type        = string
  description = "Billing account id (XXXXXX-XXXXXX-XXXXXX) to link. Supplied by the caller; the module has no default."

  validation {
    condition     = can(regex("^[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}$", var.billing_account))
    error_message = "billing_account must look like 012345-6789AB-CDEF01."
  }
}

variable "org_id" {
  type        = string
  description = "Organization id when the project is created under an organization. Null creates it with no parent."
  default     = null
}

variable "folder_id" {
  type        = string
  description = "Folder id when the project is created under a folder. Set at most one of org_id or folder_id."
  default     = null
}

variable "enabled_services" {
  type        = list(string)
  description = "APIs to enable in addition to the bootstrap services."
  default     = []
}

# Always-on APIs required to manage the project and enable other services.
variable "bootstrap_services" {
  type        = list(string)
  description = "APIs enabled on every project so later services can be turned on."
  default = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudbilling.googleapis.com",
  ]
}
