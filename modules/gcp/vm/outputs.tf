output "instance_name" {
  value = google_compute_instance.vm.name
}

output "external_ip" {
  value = var.enable_external_ip ? google_compute_address.external[0].address : null
}

output "service_account_email" {
  value = google_service_account.vm.email
}
