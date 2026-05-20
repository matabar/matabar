variable "name" {
  description = "The name of the VM"
  type        = string
}

variable "project_id" {
  description = "The project ID"
  type        = string
}

variable "machine_type" {
  description = "The machine type"
  type        = string
  default     = "f1-micro"
}

variable "zone" {
  description = "The zone to deploy the VM in"
  type        = string
}

variable "image" {
  description = "The image to use for the boot disk"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "network" {
  description = "The network to attach the VM to"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "The subnetwork to attach the VM to"
  type        = string
  default     = null
}

variable "metadata" {
  description = "Metadata for the VM"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags for the VM"
  type        = list(string)
  default     = []
}
