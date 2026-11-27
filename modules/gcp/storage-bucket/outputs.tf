output "name" {
  description = "Bucket name."
  value       = google_storage_bucket.bucket.name
}

output "url" {
  description = "gs:// URL of the bucket."
  value       = google_storage_bucket.bucket.url
}
