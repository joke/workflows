# One module block per repository. Each sets only what is specific to it.

module "zim_mise" {
  source = "./modules/repository"

  name        = "zim-mise"
  description = "zim module for mise"
  topics      = ["zim", "zimfw", "module", "zsh", "mise"]

  # integration_id is omitted: the ruleset API returned 422 "Invalid integration ids" for these
  # checks on zim-mise, even though the app IDs (68672, 198092, 1861) are the reporting apps' IDs.
  required_checks = [
    { context = "pre-commit.ci - pr" },
    { context = "Semantic PR" },
    { context = "DCO" },
  ]
}

# Classic branch protection on main, replaced by the ruleset above. It required one approval and
# code owner review. Removing it here deletes the protection on the next apply; see design.md,
# "Migrating a repository means removing its classic protection".
removed {
  from = github_branch_protection.zim_mise_classic

  lifecycle {
    destroy = true
  }
}
