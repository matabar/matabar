resource "google_service_account" "vm" {
  account_id   = "${var.hostname}-sa"
  display_name = "Service account for ${var.hostname}"
  project      = var.project_id
}

# Least-privilege IAM: logging + monitoring only.
resource "google_project_iam_member" "vm_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.vm.email}"
}

# Static external IP for stable SSH access.
resource "google_compute_address" "external" {
  count   = var.enable_external_ip ? 1 : 0
  name    = "${var.hostname}-ip"
  region  = var.region
  project = var.project_id
}

resource "google_compute_instance" "vm" {
  name         = var.hostname
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  tags         = var.tags
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {
        nat_ip = google_compute_address.external[0].address
      }
    }
  }

  metadata = var.ssh_pubkey != "" ? {
    ssh-keys = "${var.ssh_user}:${var.ssh_pubkey}"
  } : {}

  service_account {
    email  = google_service_account.vm.email
    scopes = ["cloud-platform"]
  }
}
