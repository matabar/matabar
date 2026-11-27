output "project_id" {
  description = "ID of the created project."
  value       = google_project.project.project_id
}

output "project_number" {
  description = "Numeric project number. Workload Identity Federation principals use this."
  value       = google_project.project.number
}

output "name" {
  description = "Display name of the project."
  value       = google_project.project.name
}
