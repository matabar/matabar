output "name" {
  description = "Managed zone name."
  value       = google_dns_managed_zone.this.name
}

output "dns_name" {
  description = "Zone DNS name, with a trailing dot."
  value       = google_dns_managed_zone.this.dns_name
}

output "name_servers" {
  description = "Authoritative name servers. Use these as the registrar's custom name servers."
  value       = google_dns_managed_zone.this.name_servers
}

output "dnssec_ds_records" {
  description = "DS material for the registrar. Publish the sha256 digest after the Google name servers answer."
  value = flatten([
    for key in local.active_ksks : [
      for digest in key.digests : {
        key_tag            = key.key_tag
        algorithm          = key.algorithm
        algorithm_number   = local.algorithm_numbers[key.algorithm]
        digest_type        = digest.type
        digest_type_number = local.digest_type_numbers[digest.type]
        digest             = digest.digest
        ds_record          = key.ds_record
      }
    ]
  ])
}
