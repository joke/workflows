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

provider "github" {
  owner = "joke"
}
