# Spec Delta

## Purpose

Defines how the Actions secrets that release Java and Gradle plugin repositories are stored, decrypted and set, so that the values are versioned and reviewable without being readable in git.

## ADDED Requirements

### Requirement: Secret values come from one encrypted file
The Actions secrets of the Java and Gradle plugin repositories SHALL be read from `terraform/secrets.enc.yaml`, which SHALL be encrypted with SOPS for the age recipient in `.sops.yaml`. No secret value SHALL be stored in plain text in the repository.

#### Scenario: File committed
- **WHEN** the encrypted file is committed
- **THEN** every value in it is ciphertext

#### Scenario: Recipient
- **WHEN** a value is encrypted with SOPS
- **THEN** the only recipient is the age key configured in `.sops.yaml`

### Requirement: The decryption key is an environment variable
HCP Terraform SHALL decrypt the file with the age private key in the `SOPS_AGE_KEY` environment variable of the workspace. The key SHALL NOT be a Terraform variable.

#### Scenario: Plan runs
- **WHEN** the plan runs in the workspace
- **THEN** the file is decrypted with `SOPS_AGE_KEY`

#### Scenario: Key missing
- **WHEN** `SOPS_AGE_KEY` is not set
- **THEN** the plan fails and no secret is changed

### Requirement: Placeholder values block the plan
The plan SHALL fail if any secret value in the file is the placeholder `CHANGE_ME`. No secret SHALL be set from a placeholder.

#### Scenario: Placeholder present
- **WHEN** a secret value is `CHANGE_ME`
- **THEN** the plan fails with an error naming that secret

### Requirement: Every Java and Gradle plugin repository gets the same secret set
Each Java and Gradle plugin repository SHALL have the Maven Central secrets `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`, `GPG_FINGERPRINT`, `MAVENCENTRALUSERNAME` and `MAVENCENTRALPASSWORD`, and the Gradle Plugin Portal secrets `GRADLE_PUBLISH_KEY` and `GRADLE_PUBLISH_SECRET`.

#### Scenario: Gradle plugin repository
- **WHEN** the plan is applied
- **THEN** the repository has all seven secrets with the names above

### Requirement: Secret names match what the tools read
The secret names SHALL be the names the publishing tools read directly. Repositories SHALL NOT use `ORG_GRADLE_PROJECT_*` aliases for the Gradle Plugin Portal credentials.

#### Scenario: Portal publish
- **WHEN** `publishPlugins` runs with `GRADLE_PUBLISH_KEY` and `GRADLE_PUBLISH_SECRET` in the environment
- **THEN** it authenticates with the Gradle Plugin Portal

### Requirement: Retired secrets are removed explicitly
Secrets not managed by the configuration SHALL NOT be removed by the plan. A secret is removed only by an explicit deletion, made after its replacement has been verified.

#### Scenario: Unmanaged secret present
- **WHEN** a repository has a secret that is not in the configuration
- **THEN** the plan leaves it in place

### Requirement: A value change is made in the file
A secret value SHALL be changed by re-encrypting the file with SOPS and merging the change. Terraform SHALL NOT detect a secret value changed outside the file.

#### Scenario: Key rotation
- **WHEN** a value is rotated
- **THEN** the new value is written into the encrypted file, and the plan applies it on merge
