# One YAML file per repository in repos/. The shared defaults live in modules/repository; each file
# sets the metadata and the required checks for that repository. An empty required_checks list
# skips the required status checks for that repository.

locals {
  repos = {
    for file in fileset(path.module, "repos/*.yaml") :
    trimsuffix(basename(file), ".yaml") => yamldecode(file("${path.module}/${file}"))
  }
}

module "repo" {
  source   = "./modules/repository"
  for_each = local.repos

  name            = each.value.name
  description     = each.value.description
  homepage        = each.value.homepage
  topics          = each.value.topics
  required_checks = each.value.required_checks
}

# zim-mise was the first module block; this keeps its state without recreating it.
moved {
  from = module.zim_mise
  to   = module.repo["zim-mise"]
}

# Classic branch protection on main, replaced by the ruleset. It required one approval and code
# owner review. Removing it here deletes the protection on the next apply; see design.md,
# "Migrating a repository means removing its classic protection".
removed {
  from = github_branch_protection.zim_mise_classic

  lifecycle {
    destroy = true
  }
}
