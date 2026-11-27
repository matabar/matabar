variable "name" {
  type        = string
  description = "Globally unique bucket name."
}

variable "project_id" {
  type        = string
  description = "GCP project that owns the bucket."
}

variable "location" {
  type        = string
  description = "Bucket location. Use a region such as europe-west3."
}

variable "force_destroy" {
  type        = bool
  description = "Delete objects on bucket destroy. The state bucket also sets prevent_destroy."
  default     = false
}

variable "version_retention_count" {
  type        = number
  description = "Keep this many noncurrent object versions; 0 disables pruning."
  default     = 10
}
