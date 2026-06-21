variable "name" { type = string }
variable "project_id" { type = string }
variable "location" { type = string }

variable "force_destroy" {
  type    = bool
  default = false
}

variable "version_retention_count" {
  type        = number
  description = "Keep this many archived (old) object versions; 0 disables pruning."
  default     = 10
}
