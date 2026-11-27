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

# Migration from the two-repository layout (personal-infra and matabar.online).
# Both old repositories are deleted by hand after the cutover, so state forgets
# their resources without destroying anything. Never reuse these addresses.
removed {
  from = github_repository.infra
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository.landing
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_vulnerability_alerts.infra
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_vulnerability_alerts.landing
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_pages.landing
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_ruleset.infra_main
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_ruleset.landing_main
  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_environment.production
  lifecycle {
    destroy = false
  }
}
