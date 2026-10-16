terraform {
  required_version = "1.16.6"

  cloud {

    organization = "xckk"

    workspaces {
      name = "workflows-settings"
    }
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub token with read access to joke's repositories. Set as a sensitive variable in the HCP Terraform workspace."
}

provider "github" {
  owner = "joke"
  token = var.github_token
}

# Read-only check for task 1.3: proves the workspace can reach GitHub.
data "github_repository" "zim_mise" {
  full_name = "joke/zim-mise"
}

output "zim_mise_default_branch" {
  value = data.github_repository.zim_mise.default_branch
}
