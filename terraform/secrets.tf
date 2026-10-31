# Actions secrets for the Java and Gradle plugin repositories. The values are in secrets.enc.yaml,
# encrypted with SOPS (see .sops.yaml). The age private key is the SOPS_AGE_KEY environment variable of
# the HCP Terraform workspace, never a Terraform variable. Every repository gets the Maven Central set
# and the Gradle Plugin Portal set, under the names the plugins read directly.

data "sops_file" "secrets" {
  source_file = "${path.module}/secrets.enc.yaml"
}

locals {
  java_repos = toset([
    "caffeinate",
    "claude-plugins",
    "conventional-version",
    "jspecify",
    "lint-rules",
    "percolate",
    "spock-deepmock",
    "spock-mockable",
    "spock-outputcapture",
    "spring-factory",
  ])

  maven_central_secrets = [
    "GPG_PRIVATE_KEY",
    "GPG_PASSPHRASE",
    "GPG_FINGERPRINT",
    "MAVENCENTRALUSERNAME",
    "MAVENCENTRALPASSWORD",
  ]

  gradle_publish_secrets = [
    "GRADLE_PUBLISH_KEY",
    "GRADLE_PUBLISH_SECRET",
  ]

  java_secret_names = concat(local.maven_central_secrets, local.gradle_publish_secrets)

  java_secrets = {
    for pair in setproduct(local.java_repos, local.java_secret_names) :
    "${pair[0]}/${pair[1]}" => { repo = pair[0], name = pair[1] }
  }

  # Only the names are used for for_each and checks; the values stay sensitive.
  provided_secret_names = nonsensitive(keys(data.sops_file.secrets.data))
}

# A secret missing from the file is reported as a warning and is not set.
check "java_secret_values" {
  assert {
    condition = alltrue([
      for name in local.java_secret_names : contains(local.provided_secret_names, name)
    ])
    error_message = "secrets.enc.yaml is missing one or more Java secrets; those secrets are not set."
  }
}

resource "github_actions_secret" "java" {
  for_each = {
    for key, secret in local.java_secrets : key => secret
    if contains(local.provided_secret_names, secret.name)
  }

  repository  = each.value.repo
  secret_name = each.value.name
  value       = data.sops_file.secrets.data[each.value.name]

  # The template ships with CHANGE_ME; applying it would overwrite the live secret with that text.
  lifecycle {
    precondition {
      condition     = data.sops_file.secrets.data[each.value.name] != "CHANGE_ME"
      error_message = "secrets.enc.yaml still contains the placeholder CHANGE_ME for ${each.value.name}."
    }
  }
}
