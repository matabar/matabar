include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/live/prod/databricks/provider.hcl"
}

terraform {
  source = "${get_repo_root()}/modules/databricks/lakebase"
}

inputs = {
  project_id             = "matabar-prod"
  display_name           = "Matabar Prod Lakebase"
  database_id            = "app"
  postgres_database_name = "app"
  admin_role_id          = "admin"
}
