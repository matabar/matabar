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
