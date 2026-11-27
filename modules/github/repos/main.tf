data "github_user" "reviewer" {
  username = var.reviewer_username
}

import {
  to = github_repository.infra
  id = var.infra_repository_name
}

resource "github_repository" "infra" {
  name        = var.infra_repository_name
  description = var.infra_repository_description
  # Public so rulesets and environment reviewers work on GitHub Free. The
  # repository holds no secrets; credentials live in Actions secrets and WIF.
  # trivy:ignore:AVD-GIT-0001
  visibility = "public"

  has_issues           = true
  has_projects         = true
  has_wiki             = false
  vulnerability_alerts = true

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

resource "github_repository" "landing" {
  name        = var.landing_repository_name
  description = var.landing_repository_description
  # GitHub Pages on the free plan is only available for a public repository.
  # trivy:ignore:AVD-GIT-0001
  visibility   = "public"
  homepage_url = "https://${var.pages_domain}"
  auto_init    = true
  topics       = ["github-pages"]

  has_issues           = true
  has_projects         = false
  has_wiki             = false
  vulnerability_alerts = true

  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = true
  delete_branch_on_merge = true
  allow_update_branch    = true

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [pages]
  }
}

resource "github_repository_pages" "landing" {
  repository = github_repository.landing.name

  # GitHub Actions publishes the site. The workflow itself lives in the
  # landing repository, not in this one.
  build_type = "workflow"
  cname      = var.pages_domain

  # GitHub rejects https_enforced until DNS points at Pages and the
  # certificate state is "issued". First apply keeps this false.
  https_enforced = var.pages_https_enforced
}

resource "github_repository_ruleset" "infra_main" {
  name        = "protect-main"
  repository  = github_repository.infra.name
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
        for_each = toset(var.infra_required_checks)
        content {
          context = required_check.value
        }
      }
    }
  }
}

resource "github_repository_ruleset" "landing_main" {
  name        = "protect-main"
  repository  = github_repository.landing.name
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
  }
}

resource "github_repository_environment" "production" {
  repository  = github_repository.infra.name
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
