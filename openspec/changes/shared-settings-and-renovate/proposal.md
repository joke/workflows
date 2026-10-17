# Proposal

## Why

Each repository keeps its own copy of repository settings, Dependabot configuration and approval rules. The copies have already drifted apart between the Gradle libraries and the zim modules, and every new repository repeats the setup by hand. A single structure for all repositories keeps the policy in one place while each repository keeps its own identity.

## What Changes

- Repository settings, branch protection and Dependabot security settings for every repository are managed by Terraform in this repository (`joke/workflows`), using the GitHub provider. HCP Terraform runs the plan on pull requests and the apply on merge.
- Each repository's metadata (name, description, homepage, topics) and its required status checks are one YAML file under `terraform/repos/`. Repositories in the same group share one check list:
  - **zim modules:** `pre-commit.ci - pr`, `Semantic PR`, `DCO`.
  - **Gradle libraries:** `pre-commit.ci - pr`, `Semantic PR` and `build`. DCO is not used, because its app does not report on these repositories. CodeQL and codecov checks and their workflows are removed.
  - **Metadata-only repositories:** the shared merge and branch settings, but no required checks, because they have no pipeline to report them.
- The build and release of every Gradle library, and the release of every zim module, are reusable workflows in this repository. Each repository's `build.yml` and `release.yml` only call them. Codecov and CodeQL are removed, and every repository uses mise.
- The asdf plugin repositories are archived and are not managed.
- Probot's per-repository `settings.yml` is removed from each repository during its cutover, so Probot no longer applies settings.
- Dependabot version updates are replaced by Renovate. One shared preset lives in this repository at `renovate/default.json`. Each repository keeps a small `renovate.json` that extends it.
- Renovate pull requests are never auto-merged. A person merges them.
- Dependabot security alerts stay enabled as a repository setting. Only the version-update configuration moves to Renovate.
- Required approving reviews are set to 0 across repositories, and the `autoapproval.yml` workflows that approved PRs are removed.
- **BREAKING** for each repository: its `.github/settings.yml` and `.github/dependabot.yml` are removed when it moves to Terraform and Renovate.

## Capabilities

### New Capabilities

None. This change alters repository tooling and configuration only. It does not change behavior of any product.

### Modified Capabilities

None.

This change is tooling-only, so the change sets `skip_specs: true`.

## Impact

- **This repository (`joke/workflows`):** gains the Terraform configuration under `terraform/`, and the HCP Terraform workspace that plans and applies it.
- **This repository (`joke/workflows`):** also holds the shared Renovate preset at `renovate/default.json`. The separate `joke/renovate-config` repository is deleted.
- **Every repository:** loses `.github/settings.yml` and `.github/dependabot.yml`, and gets a `renovate.json` that extends the preset. Its settings come from the Terraform configuration.
- **External services:** HCP Terraform (free tier, up to 500 managed resources) and the Renovate GitHub App need access to the repositories. Installing the Renovate app and connecting the HCP Terraform workspace are one-time manual steps.
- **Rollout order:** Terraform is tested on `zim-mise` first; Renovate is tested on `spock-deepmock` first, where its Dependabot ignore rules are ported.
