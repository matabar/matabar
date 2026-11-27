output "pool_name" {
  description = "Full resource name of the Workload Identity pool."
  value       = google_iam_workload_identity_pool.github.name
}

output "plan_workload_identity_provider" {
  description = "Provider resource name for google-github-actions/auth on plan jobs. Store as the WIF_PLAN_PROVIDER repository variable."
  value       = google_iam_workload_identity_pool_provider.plan.name
}

output "apply_workload_identity_provider" {
  description = "Provider resource name for google-github-actions/auth on apply jobs. Store as the WIF_APPLY_PROVIDER repository variable."
  value       = google_iam_workload_identity_pool_provider.apply.name
}

output "plan_service_account" {
  description = "Plan service account email. Store as the WIF_PLAN_SERVICE_ACCOUNT repository variable."
  value       = google_service_account.plan.email
}

output "apply_service_account" {
  description = "Apply service account email. Store as the WIF_APPLY_SERVICE_ACCOUNT repository variable."
  value       = google_service_account.apply.email
}
