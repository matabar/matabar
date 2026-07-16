variable "iap_tunnel_members" {
  type        = list(string)
  description = "IAM members granted roles/iap.tunnelResourceAccessor on this instance."
  default     = []
}

resource "google_iap_tunnel_instance_iam_member" "tunnel" {
  for_each = toset(var.iap_tunnel_members)

  project  = var.project_id
  zone     = var.zone
  instance = google_compute_instance.vm.name
  role     = "roles/iap.tunnelResourceAccessor"
  member   = each.value
}
