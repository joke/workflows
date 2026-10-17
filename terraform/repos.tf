# One YAML file per repository in repos/. The shared defaults live in modules/repository; each file
# sets the metadata and the required checks for that repository. An empty required_checks list
# skips the required status checks for that repository.

locals {
  repos = {
    for file in fileset(path.module, "repos/*.yaml") :
    trimsuffix(basename(file), ".yaml") => yamldecode(file("${path.module}/${file}"))
  }
}

# Repositories whose classic branch protection is still in state. Set during the import of the
# classic protection; empty once it has been removed.
variable "legacy_protection_repos" {
  type        = list(string)
  description = "Repositories whose classic branch protection on main is still managed. Empty removes it."
  default     = []
}

module "repo" {
  source   = "./modules/repository"
  for_each = local.repos

  name              = each.value.name
  description       = each.value.description
  homepage          = each.value.homepage
  topics            = each.value.topics
  required_checks   = each.value.required_checks
  legacy_protection = contains(var.legacy_protection_repos, each.key)
}

# zim-mise was the first module block; this keeps its state without recreating it.
moved {
  from = module.zim_mise
  to   = module.repo["zim-mise"]
}

# Classic branch protection on main for zim-mise, replaced by the ruleset. Removed; see design.md,
# "Migrating a repository means removing its classic protection".
removed {
  from = github_branch_protection.zim_mise_classic

  lifecycle {
    destroy = true
  }
}
