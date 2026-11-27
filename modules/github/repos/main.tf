data "github_user" "reviewer" {
  username = var.reviewer_username
}

import {
  to = github_repository.this
  id = var.repository_name
}

resource "github_repository" "this" {
  name        = var.repository_name
  description = var.repository_description
  # Public so rulesets, environment reviewers and GitHub Pages work on GitHub
  # Free. The repository holds no secrets; credentials live in Actions secrets
  # and WIF.
  # trivy:ignore:AVD-GIT-0001
  visibility   = "public"
  homepage_url = "https://${var.pages_domain}"

  has_issues   = true
  has_projects = true
  has_wiki     = false

  # Linear history: squash or rebase, never a merge commit.
  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = false
  delete_branch_on_merge = true
  allow_update_branch    = true

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [pages]
  }
}

# vulnerability_alerts on github_repository is deprecated. This import adopts
# the alerts already enabled on the repository.
import {
  to = github_repository_vulnerability_alerts.this
  id = var.repository_name
}

resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
  enabled    = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_pages" "this" {
  repository = github_repository.this.name

  # GitHub Actions publishes the site from site/ (see the Pages workflow).
  build_type = "workflow"
  cname      = var.pages_domain

  # Any https_enforced value, even false, makes the provider send the field,
  # and GitHub answers "404 The certificate does not exist yet" until DNS
  # points at Pages and the certificate is issued. Leave it unset (null)
  # until then; set pages_https_enforced = true afterwards.
  https_enforced = var.pages_https_enforced ? true : null
}

# Provider 6.13.0 (the latest release) drops the custom domain on Pages
# writes: create ignores cname, and update sends "cname": null whenever cname
# itself did not change (integrations/terraform-provider-github#3450). Changing
# only https_enforced or build_type therefore unsets the domain, and GitHub
# discards the certificate with it. This helper runs after every Pages create
# or change, puts the domain back, and fails the apply unless the API reports
# it. Remove it once a provider release always sends cname. It needs curl and
# the GITHUB_TOKEN the provider already uses.
resource "terraform_data" "pages_cname" {
  triggers_replace = [
    github_repository_pages.this.id,
    var.pages_domain,
    var.pages_https_enforced,
    github_repository_pages.this.build_type,
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      PAGES_API = "https://api.github.com/repos/${github_repository.this.full_name}/pages"
      DOMAIN    = var.pages_domain
    }
    command = <<-EOT
      set -eu
      get() { curl -sS -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$PAGES_API" | tr -d ' ' | grep -o '"cname":[^,]*' || true; }
      want="\"cname\":\"$DOMAIN\""
      if [ "$(get)" != "$want" ]; then
        curl -sS -X PUT -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$PAGES_API" -d "{$want}" > /dev/null || true
      fi
      got="$(get)"
      [ "$got" = "$want" ] || { echo "Pages cname is not $DOMAIN (API reports: $got)" >&2; exit 1; }
    EOT
  }
}

resource "github_repository_ruleset" "main" {
  name        = "protect-main"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true

    pull_request {
      required_approving_review_count = 0
      dismiss_stale_reviews_on_push   = true
      allowed_merge_methods           = ["squash", "rebase"]
    }

    required_status_checks {
      strict_required_status_checks_policy = true
      do_not_enforce_on_create             = true

      dynamic "required_check" {
        for_each = toset(var.required_checks)
        content {
          context = required_check.value
        }
      }
    }
  }
}

resource "github_repository_environment" "deploy" {
  repository  = github_repository.this.name
  environment = var.production_environment

  # The owner approves their own apply. prevent_self_review would deadlock
  # a repository with one person.
  prevent_self_review = false

  reviewers {
    users = [data.github_user.reviewer.id]
  }

  deployment_branch_policy {
    protected_branches     = true
    custom_branch_policies = false
  }
}
