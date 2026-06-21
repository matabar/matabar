output "project_name" {
  description = "Full resource name of the Lakebase project."
  value       = databricks_postgres_project.this.name
}

output "branch_name" {
  description = "Full resource name of the production branch."
  value       = databricks_postgres_branch.production.name
}

output "endpoint_name" {
  description = "Full resource name of the primary read-write endpoint."
  value       = databricks_postgres_endpoint.primary.name
}

output "database_name" {
  description = "Full resource name of the application database."
  value       = databricks_postgres_database.app.name
}

output "admin_role_name" {
  description = "Full resource name of the admin Postgres role."
  value       = databricks_postgres_role.admin.name
}
