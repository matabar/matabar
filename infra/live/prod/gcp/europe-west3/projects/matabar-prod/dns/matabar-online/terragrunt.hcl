include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "provider" {
  path = "${get_repo_root()}/infra/live/prod/gcp/provider.hcl"
}

terraform {
  source = "${get_repo_root()}/infra/modules/gcp/dns-zone"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals

  # Paste the value GitHub shows for _github-pages-challenge-matabar after the
  # custom domain is saved. Empty omits the record. Export it as
  # PAGES_CHALLENGE locally, or set that repository variable for CI.
  github_pages_challenge = get_env("PAGES_CHALLENGE", "")

  # https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site
  pages_records = {
    apex_a = {
      name = "@"
      type = "A"
      ttl  = 3600
      rrdatas = [
        "185.199.108.153",
        "185.199.109.153",
        "185.199.110.153",
        "185.199.111.153",
      ]
    }
    apex_aaaa = {
      name = "@"
      type = "AAAA"
      ttl  = 3600
      rrdatas = [
        "2606:50c0:8000::153",
        "2606:50c0:8001::153",
        "2606:50c0:8002::153",
        "2606:50c0:8003::153",
      ]
    }
    www = {
      name    = "www"
      type    = "CNAME"
      ttl     = 3600
      rrdatas = ["${local.env.github_owner}.github.io."]
    }
  }

  pages_challenge_record = {
    github_pages_challenge = {
      name    = "_github-pages-challenge-${local.env.github_owner}"
      type    = "TXT"
      ttl     = 3600
      rrdatas = ["\"${local.github_pages_challenge}\""]
    }
  }

  # Off until a forwarder is chosen. Turning this on publishes ImprovMX MX
  # and SPF records and does not create the ImprovMX account. See infra/README.md.
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

# Ordering only. Bootstrap units keep local state, so their outputs are not
# readable in CI or on a fresh clone. Shared values come from env.hcl.
dependencies {
  paths = [
    "../../project",
  ]
}

inputs = {
  project_id  = local.env.project_id
  name        = "matabar-online"
  dns_name    = local.env.domain
  description = "Public DNS for ${local.env.domain}"
  labels = {
    environment = local.env.environment
    managed_by  = "terragrunt"
  }

  dnssec_enabled = true
  record_sets = merge(
    local.pages_records,
    local.github_pages_challenge == "" ? {} : local.pages_challenge_record,
    local.enable_email_forwarding ? local.email_forwarding_records : {},
  )
}
