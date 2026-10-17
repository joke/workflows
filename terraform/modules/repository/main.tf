# Shared repository settings. Each repository supplies only its name, description, topics and
# required checks; everything else is the same for every repository.
#
# Every value below that Probot or GitHub would otherwise default is set explicitly, so applying
# the module does not change an existing repository's unmanaged settings.

resource "github_repository" "this" {
  name         = var.name
  description  = var.description
  homepage_url = var.homepage
  topics       = var.topics
  visibility   = "public"

  allow_squash_merge          = false
  allow_merge_commit          = false
  allow_rebase_merge          = true
  allow_auto_merge            = true
  allow_update_branch         = true
  delete_branch_on_merge      = true
  web_commit_signoff_required = false

  has_issues   = true
  has_projects = false
  has_wiki     = false

  # Never delete a repository by accident. Destroying the resource archives it instead.
  archive_on_destroy = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
  enabled    = true
}

resource "github_repository_dependabot_security_updates" "this" {
  repository = github_repository.this.name
  enabled    = true
}

resource "github_repository_ruleset" "main" {
  repository  = github_repository.this.name
  name        = "main"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  # Repository admins can bypass the ruleset, matching enforce_admins: false on the old protection.
  bypass_actors {
    actor_id    = 5
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  rules {
    required_linear_history = true

    pull_request {
      # No approval is required; see design.md, "No required approvals".
      required_approving_review_count   = 0
      require_code_owner_review         = false
      dismiss_stale_reviews_on_push     = true
      required_review_thread_resolution = true
    }

    dynamic "required_status_checks" {
      for_each = length(var.required_checks) > 0 ? [1] : []

      content {
        strict_required_status_checks_policy = true

        dynamic "required_check" {
          for_each = var.required_checks
          content {
            context = required_check.value
          }
        }
      }
    }
  }
}

# Classic branch protection on main, replaced by the ruleset above. It is imported first, then
# removed by setting legacy_protection to false.
resource "github_branch_protection" "legacy" {
  count = var.legacy_protection ? 1 : 0

  repository_id = github_repository.this.node_id
  pattern       = "main"
}
