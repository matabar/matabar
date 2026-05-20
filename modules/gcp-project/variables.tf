variable "name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The project ID"
  type        = string
}

variable "billing_account" {
  description = "The billing account ID"
  type        = string
}

variable "org_id" {
  description = "The organization ID"
  type        = string
  default     = null
}

variable "folder_id" {
  description = "The folder ID"
  type        = string
  default     = null
}

variable "enabled_services" {
  description = "The list of services to enable"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "oslogin.googleapis.com"
  ]
}
