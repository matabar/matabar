variable "hostname" { type = string }
variable "project_id" { type = string }
variable "machine_type" { type = string }
variable "zone" { type = string }
variable "image" {
  type    = string
  default = "debian-cloud/debian-12"
}
variable "network" { type = string }
variable "subnetwork" { type = string }
