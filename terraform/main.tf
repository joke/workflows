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
  description = "GitHub token with administration rights on the managed repositories. Set as a sensitive variable in the HCP Terraform workspace."
}

provider "github" {
  owner = "joke"
  token = var.github_token
}
