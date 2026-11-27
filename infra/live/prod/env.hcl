locals {
  environment = "prod"

  # Single source for the GCP project. Change project_id here if the id is
  # already taken; do not repeat it in modules.
  project_name    = "matabar-prod"
  project_id      = "matabar-online-prod"
  billing_account = "01840C-61ACE5-5FE73D"

  # Leave both null to create the project with no organization parent.
  # A personal Google account usually has to do that. If the account is in
  # Cloud Identity or Workspace, set exactly one of these (the other stays null).
  org_id    = null
  folder_id = null

  # Must match the bucket created by bootstrap/tfstate. root.hcl reads this.
  state_bucket = "matabar-prod-tfstate"

  github_owner = "matabar"
  domain       = "matabar.online"
}
