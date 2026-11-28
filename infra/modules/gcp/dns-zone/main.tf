locals {
  dns_name = endswith(var.dns_name, ".") ? var.dns_name : "${var.dns_name}."

  record_sets = {
    for key, record in var.record_sets : key => {
      name = (
        record.name == "@" || record.name == "" ? local.dns_name :
        endswith(record.name, ".") ? record.name :
        "${trimsuffix(record.name, ".")}.${local.dns_name}"
      )
      type    = upper(record.type)
      ttl     = record.ttl
      rrdatas = record.rrdatas
    }
  }

  # IANA numbers for the registrar form. Cloud DNS returns the mnemonic.
  algorithm_numbers = {
    ecdsap256sha256 = 13
    ecdsap384sha384 = 14
    rsasha256       = 8
    rsasha512       = 10
  }

  digest_type_numbers = {
    sha1   = 1
    sha256 = 2
    sha384 = 4
  }

  active_ksks = var.dnssec_enabled ? [
    for key in data.google_dns_keys.this[0].key_signing_keys : key
    if key.is_active
  ] : []
}

resource "google_dns_managed_zone" "this" {
  name          = var.name
  dns_name      = local.dns_name
  description   = var.description
  project       = var.project_id
  labels        = var.labels
  visibility    = "public"
  force_destroy = var.force_destroy

  # ECDSA P-256 and NSEC3. Both key specs are required when either is set,
  # and they can only be changed while DNSSEC is off, so they are fixed here.
  dynamic "dnssec_config" {
    for_each = var.dnssec_enabled ? [1] : []
    content {
      state         = "on"
      non_existence = "nsec3"

      default_key_specs {
        algorithm  = "ecdsap256sha256"
        key_length = 256
        key_type   = "keySigning"
      }

      default_key_specs {
        algorithm  = "ecdsap256sha256"
        key_length = 256
        key_type   = "zoneSigning"
      }
    }
  }
}

data "google_dns_keys" "this" {
  count = var.dnssec_enabled ? 1 : 0

  managed_zone = google_dns_managed_zone.this.name
  project      = var.project_id
}

resource "google_dns_record_set" "this" {
  for_each = local.record_sets

  managed_zone = google_dns_managed_zone.this.name
  project      = var.project_id
  name         = each.value.name
  type         = each.value.type
  ttl          = each.value.ttl
  rrdatas      = each.value.rrdatas

  lifecycle {
    precondition {
      condition     = !(each.value.name == local.dns_name && contains(["NS", "SOA"], each.value.type))
      error_message = "Cloud DNS publishes the apex NS and SOA records. Remove ${each.key} from record_sets."
    }
  }
}
# t
