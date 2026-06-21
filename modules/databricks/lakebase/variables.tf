variable "project_id" {
  description = "Lakebase project ID (kebab-case)."
  type        = string
}

variable "display_name" {
  description = "Human-readable display name for the Lakebase project."
  type        = string
}

variable "pg_version" {
  description = "Postgres major version for the Lakebase project."
  type        = number
  default     = 17
}

variable "enable_pg_native_login" {
  description = "Allow native Postgres roles to connect with static passwords."
  type        = bool
  default     = false
}

variable "database_id" {
  description = "Lakebase database resource ID."
  type        = string
}

variable "postgres_database_name" {
  description = "Postgres database name inside the branch."
  type        = string
}

variable "admin_role_id" {
  description = "Lakebase role ID for the admin role."
  type        = string
}

variable "autoscaling_limit_min_cu" {
  description = "Minimum compute units for the primary endpoint."
  type        = number
  default     = 0.5
}

variable "autoscaling_limit_max_cu" {
  description = "Maximum compute units for the primary endpoint."
  type        = number
  default     = 1
}

variable "suspend_timeout_duration" {
  description = "Inactivity duration before the endpoint suspends (e.g. 300s). Null disables suspension config."
  type        = string
  default     = null
}
