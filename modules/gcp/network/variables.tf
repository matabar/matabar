variable "project_id" { type = string }
variable "region" { type = string }

variable "network_name" {
  type    = string
  default = "prod-network"
}

variable "subnet_name" {
  type    = string
  default = "prod-subnet"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "ssh_source_ranges" {
  type        = list(string)
  description = "CIDR ranges permitted to reach tcp/22. Empty disables the SSH rule."
  default     = []
}

variable "https_source_ranges" {
  type        = list(string)
  description = "CIDR ranges permitted to reach tcp/80 and tcp/443. Empty disables the HTTPS rule."
  default     = ["0.0.0.0/0"]
}

variable "https_target_tags" {
  type        = list(string)
  description = "Network tags on instances that receive inbound HTTP/HTTPS."
  default     = ["https"]
}
