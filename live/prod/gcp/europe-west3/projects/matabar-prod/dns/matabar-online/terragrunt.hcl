include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/live/prod/gcp/provider.hcl"
}

terraform {
  source = "${get_repo_root()}/modules/gcp/dns-zone"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals

  # Off until a forwarder is chosen. Turning this on publishes ImprovMX MX
  # and SPF records and does not create the ImprovMX account. See README.
  enable_email_forwarding = false

  email_forwarding_records = {
    mx = {
      name = "@"
      type = "MX"
      ttl  = 3600
      rrdatas = [
        "10 mx1.improvmx.com.",
        "20 mx2.improvmx.com.",
      ]
    }
    spf = {
      name    = "@"
      type    = "TXT"
      ttl     = 3600
      rrdatas = ["\"v=spf1 include:spf.improvmx.com ~all\""]
    }
  }
}

dependency "project" {
  config_path = "../../project"
  mock_outputs = {
    project_id = "matabar-online-prod"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  project_id  = dependency.project.outputs.project_id
  name        = "matabar-online"
  dns_name    = "matabar.online"
  description = "Public DNS for matabar.online"
  labels = {
    environment = local.env.environment
    managed_by  = "terragrunt"
  }

  dnssec_enabled = true
  record_sets    = local.enable_email_forwarding ? local.email_forwarding_records : {}
}
