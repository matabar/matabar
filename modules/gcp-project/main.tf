resource "google_project" "project" {
  name            = var.name
  project_id      = var.project_id
  billing_account = var.billing_account
  org_id          = var.org_id
  folder_id       = var.folder_id
}

resource "google_project_service" "services" {
  for_each = toset(var.enabled_services)
  project  = google_project.project.project_id
  service  = each.key

  disable_on_destroy = false
}
