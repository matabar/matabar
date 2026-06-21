resource "google_storage_bucket" "bucket" {
  name     = var.name
  project  = var.project_id
  location = var.location

  force_destroy               = var.force_destroy
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  dynamic "lifecycle_rule" {
    for_each = var.version_retention_count > 0 ? [1] : []
    content {
      action {
        type = "Delete"
      }
      condition {
        num_newer_versions = var.version_retention_count
        with_state         = "ARCHIVED"
      }
    }
  }
}
