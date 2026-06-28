variable "hostname" { type = string }
variable "project_id" { type = string }
variable "machine_type" { type = string }
variable "zone" { type = string }
variable "region" { type = string }
variable "image" {
  type    = string
  default = "debian-cloud/debian-12"
}
variable "network" { type = string }
variable "subnetwork" { type = string }

variable "enable_external_ip" {
  type    = bool
  default = true
}

variable "ssh_user" {
  type    = string
  default = ""
}

variable "ssh_pubkey" {
  type        = string
  description = "Public key contents pushed via instance metadata."
  default     = ""
}

variable "tags" {
  type    = list(string)
  default = ["ssh"]
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "enable_web_stack" {
  type        = bool
  description = "Bootstrap Docker, nginx, and certbot via cloud-init user-data."
  default     = false
}

variable "web_domain" {
  type        = string
  description = "Public FQDN for nginx and Let's Encrypt (e.g. matabar.duckdns.org)."
  default     = ""
}

variable "certbot_email" {
  type        = string
  description = "Email for Let's Encrypt registration. Pass via TF_VAR_certbot_email."
  sensitive   = true
  default     = ""
}

variable "app_upstream_port" {
  type        = number
  description = "Local port nginx proxies to (docker-compose binds 127.0.0.1:port)."
  default     = 8080
}

variable "docker_compose_content" {
  type        = string
  description = "Full docker-compose.yml body. Empty uses the module default template."
  default     = ""
}
