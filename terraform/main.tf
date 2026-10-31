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
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.2"
    }
  }
}

provider "github" {
  owner = "joke"
}

# Decrypts secrets.enc.yaml with the age key in the SOPS_AGE_KEY environment variable of the workspace.
provider "sops" {}
