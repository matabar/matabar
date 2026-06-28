variable "duckdns_token" {
  type        = string
  description = "DuckDNS API token. Pass via TF_VAR_duckdns_token; never commit."
  sensitive   = true
  default     = ""
}

variable "duckdns_subdomain" {
  type        = string
  description = "DuckDNS subdomain label (e.g. matabar -> matabar.duckdns.org)."
  default     = ""
}

resource "terraform_data" "duckdns_update" {
  count = var.enable_web_stack && var.enable_external_ip && var.duckdns_subdomain != "" && var.duckdns_token != "" ? 1 : 0

  triggers_replace = [google_compute_address.external[0].address]

  provisioner "local-exec" {
    command = "curl -fsS 'https://www.duckdns.org/update?domains=${var.duckdns_subdomain}&token=${var.duckdns_token}&ip=${google_compute_address.external[0].address}'"
  }

  depends_on = [google_compute_address.external]
}
