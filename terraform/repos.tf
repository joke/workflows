# One module block per repository. Each sets only what is specific to it.

module "zim_mise" {
  source = "./modules/repository"

  name        = "zim-mise"
  description = "zim module for mise"
  topics      = ["zim", "zimfw", "module", "zsh", "mise"]

  required_checks = [
    { context = "pre-commit.ci - pr", integration_id = 68672 },
    { context = "Semantic PR", integration_id = 198092 },
    { context = "DCO", integration_id = 1861 },
  ]
}
