variable "name" { type = string }
variable "project_id" { type = string }
variable "billing_account" { type = string }
variable "org_id" {
  type    = string
  default = null
}
variable "folder_id" {
  type    = string
  default = null
}
variable "enabled_services" {
  type    = list(string)
  default = []
}

# Always-on APIs required to manage the project and enable other services.
variable "bootstrap_services" {
  type = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
  ]
}
