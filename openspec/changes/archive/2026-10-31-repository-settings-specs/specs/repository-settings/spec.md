# Spec Delta

## Purpose

Defines how the GitHub repositories of the owner are configured: one Terraform configuration in joke/workflows sets the merge, branch, ruleset and security settings that every managed repository shares.

## ADDED Requirements

### Requirement: Every managed repository is declared in Terraform
Each managed repository SHALL have one YAML file in `terraform/repos/` that sets its name, description, homepage, topics and required checks. A repository without that file SHALL NOT be changed by the configuration.

#### Scenario: Repository with a declaration
- **WHEN** `terraform/repos/<name>.yaml` exists
- **THEN** the plan manages that repository with the shared defaults and its own metadata and required checks

#### Scenario: Repository without a declaration
- **WHEN** a repository has no file in `terraform/repos/`
- **THEN** the configuration does not create, change or remove it

### Requirement: Shared defaults apply to every managed repository
Every managed repository SHALL use the same merge settings: squash and merge commits disabled, rebase merges allowed, auto-merge and update-branch allowed, and the branch deleted after merge. Vulnerability alerts and automated security fixes SHALL be enabled.

#### Scenario: Settings applied
- **WHEN** the plan applies to a managed repository
- **THEN** its merge settings, vulnerability alerts and automated security fixes match the shared defaults

### Requirement: Main is protected by a ruleset without bypass
Each managed repository SHALL have an active ruleset on `main` that requires linear history, pull requests, and resolved conversations. The ruleset SHALL have no bypass actors, so no user, including repository administrators, can push to `main` directly.

#### Scenario: Direct push to main
- **WHEN** any user pushes a commit directly to `main`
- **THEN** GitHub rejects the push

#### Scenario: Pull request merge
- **WHEN** a pull request targets `main` and passes its required checks
- **THEN** it can be merged, with a rebase or fast-forward history

### Requirement: No approving review is required
The ruleset SHALL require zero approving reviews and SHALL NOT require code-owner review. Approvals SHALL NOT be a condition for merging.

#### Scenario: Pull request without approval
- **WHEN** a pull request has no approving review and passes its required checks
- **THEN** it can be merged

### Requirement: Required checks come from the repository's group
A repository SHALL require the status checks of its group: Gradle libraries require `pre-commit.ci - pr`, `Semantic PR` and `build / build`; zim modules require `pre-commit.ci - pr`, `Semantic PR` and `DCO`; metadata-only repositories require none.

#### Scenario: Gradle library
- **WHEN** a Gradle library's pull request is checked
- **THEN** the merge is blocked until `pre-commit.ci - pr`, `Semantic PR` and `build / build` pass

#### Scenario: Metadata-only repository
- **WHEN** a metadata-only repository has no required checks declared
- **THEN** its pull requests have no required status checks

### Requirement: Default workflow permissions allow release-please
Each managed repository SHALL set the default workflow token to read and write, and SHALL allow GitHub Actions to create and approve pull requests.

#### Scenario: Release-please opens a pull request
- **WHEN** release-please runs with the default token
- **THEN** it can create the release pull request

### Requirement: Repositories are never destroyed by the configuration
Removing a repository declaration SHALL NOT delete the repository. Destroying a managed repository SHALL archive it instead.

#### Scenario: Declaration removed
- **WHEN** a repository's file is deleted from `terraform/repos/`
- **THEN** the plan archives the repository rather than deleting it
