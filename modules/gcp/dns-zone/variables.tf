variable "project_id" {
  type        = string
  description = "GCP project that owns the public zone."
}

variable "name" {
  type        = string
  description = "Cloud DNS managed zone name (not the domain). Lowercase letters, numbers, and dashes."
}

variable "dns_name" {
  type        = string
  description = "Domain name, with or without a trailing dot. Example: matabar.online."
}

variable "description" {
  type        = string
  description = "Zone description shown in Cloud DNS."
  default     = "Public DNS zone"
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to the managed zone."
  default     = {}
}

variable "dnssec_enabled" {
  type        = bool
  description = "Sign the zone. The registrar DS record comes from the outputs after apply."
  default     = true
}

variable "force_destroy" {
  type        = bool
  description = "Delete leftover records when destroying the zone."
  default     = false
}

variable "record_sets" {
  type = map(object({
    name    = string
    type    = string
    ttl     = number
    rrdatas = list(string)
  }))
  description = <<-EOT
    Record sets keyed by a stable name. name is "@" for the apex, a relative
    label such as "www", or a fully qualified name ending in a dot.
    TXT rrdatas must include the surrounding quotes.
    Do not declare the apex NS or SOA records; Cloud DNS publishes those.
  EOT
  default     = {}

  validation {
    condition = alltrue([
      for record in values(var.record_sets) : contains([
        "A", "AAAA", "CAA", "CNAME", "HTTPS", "MX", "NAPTR", "NS", "PTR",
        "SRV", "SSHFP", "SVCB", "TLSA", "TXT",
      ], upper(record.type))
    ])
    error_message = "record_sets type must be a record type this module publishes."
  }

  validation {
    condition = alltrue([
      for record in values(var.record_sets) :
      record.ttl >= 0 && record.ttl <= 259200 && length(record.rrdatas) > 0
    ])
    error_message = "Each record set needs at least one rrdata and a TTL no higher than 259200 (Cloud DNS DNSSEC guidance)."
  }
}
