# GCP Project Module

This module creates a GCP project and enables a list of services.

## Usage

```hcl
module "project" {
  source = "../../modules/gcp-project"

  name             = "my-project"
  project_id       = "my-project-id"
  billing_account  = "000000-000000-000000"
  enabled_services = ["compute.googleapis.com"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the project | `string` | n/a | yes |
| project_id | The project ID | `string` | n/a | yes |
| billing_account | The billing account ID | `string` | n/a | yes |
| org_id | The organization ID | `string` | `null` | no |
| folder_id | The folder ID | `string` | `null` | no |
| enabled_services | The list of services to enable | `list(string)` | `["compute.googleapis.com", "oslogin.googleapis.com"]` | no |

## Outputs

| Name | Description |
|------|-------------|
| project_id | The project ID |
| project_number | The project number |
