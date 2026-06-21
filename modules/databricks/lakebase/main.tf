resource "databricks_postgres_project" "this" {
  project_id = var.project_id

  spec = {
    pg_version             = var.pg_version
    display_name           = var.display_name
    enable_pg_native_login = var.enable_pg_native_login
  }
}

resource "databricks_postgres_branch" "production" {
  branch_id        = "production"
  parent           = databricks_postgres_project.this.name
  replace_existing = true

  spec = {
    protected = true
  }
}

resource "databricks_postgres_endpoint" "primary" {
  endpoint_id      = "primary"
  parent           = databricks_postgres_branch.production.name
  replace_existing = true

  spec = merge(
    {
      endpoint_type            = "ENDPOINT_TYPE_READ_WRITE"
      autoscaling_limit_min_cu = var.autoscaling_limit_min_cu
      autoscaling_limit_max_cu = var.autoscaling_limit_max_cu
    },
    var.suspend_timeout_duration != null ? { suspend_timeout_duration = var.suspend_timeout_duration } : {},
  )

  depends_on = [databricks_postgres_branch.production]
}

resource "databricks_postgres_role" "admin" {
  role_id = var.admin_role_id
  parent  = databricks_postgres_branch.production.name

  spec = {
    postgres_role    = var.admin_role_id
    membership_roles = ["DATABRICKS_SUPERUSER"]
  }

  depends_on = [databricks_postgres_endpoint.primary]
}

resource "databricks_postgres_database" "app" {
  database_id = var.database_id
  parent      = databricks_postgres_branch.production.name

  spec = {
    postgres_database = var.postgres_database_name
    role              = databricks_postgres_role.admin.name
  }

  depends_on = [databricks_postgres_role.admin]
}
