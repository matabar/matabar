# GCP VM Module

This module creates a Compute Engine instance in GCP.

## Usage

```hcl
module "vm" {
  source = "../../modules/gcp-vm"

  name         = "my-vm"
  project_id   = "my-project-id"
  zone         = "europe-west3-a"
  machine_type = "f1-micro"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the VM | `string` | n/a | yes |
| project_id | The project ID | `string` | n/a | yes |
| machine_type | The machine type | `string` | `f1-micro` | no |
| zone | The zone to deploy the VM in | `string` | n/a | yes |
| image | The image to use for the boot disk | `string` | `debian-cloud/debian-11` | no |
| network | The network to attach the VM to | `string` | `default` | no |
| subnetwork | The subnetwork to attach the VM to | `string` | `null` | no |
| metadata | Metadata for the VM | `map(string)` | `{}` | no |
| tags | Tags for the VM | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | The instance ID |
| public_ip | The public IP of the instance |
| private_ip | The private IP of the instance |
