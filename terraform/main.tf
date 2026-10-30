terraform {
  required_version = "1.17.1"

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
