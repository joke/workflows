# Design

## Context

Repository settings, branch protection and Dependabot configuration are set per repository. Settings are defined in `.github/settings.yml`, which the Probot settings app reads and applies. Dependabot reads `.github/dependabot.yml` from each repository's default branch. The Gradle libraries (`spock-deepmock` and siblings) and the zim modules already use both files, and the copies differ: the required checks differ, and the zim modules require one approval where the Gradle libraries require none. See proposal.md for the motivation.

Probot's `_extends` was the first plan for sharing settings. It was tested and works for syntax, but it cannot pin a version, and nothing re-syncs a child repository when its base changes. That leaves no notification and no rollout trigger, so this change moves settings management to Terraform. The test results are recorded below because they informed the choice.

Dependabot has no way to inherit configuration from another repository. Renovate can extend a preset hosted in a GitHub repository, so one preset can serve every repository.

## Goals / Non-Goals

**Goals:**
- One Terraform configuration in `joke/workflows` that describes every repository's settings, branch protection and Dependabot security settings.
- Plans shown on pull requests, and applies on merge to `main`, run by HCP Terraform.
- One Renovate preset that every repository extends.
- Each repository's metadata (name, description, homepage, topics) and its required checks come from one YAML file per repository under `terraform/repos/`. Repositories in a group share one check list.

**Non-Goals:**
- Sharing workflows through reusable workflows or a configurable central workflow. Each repository keeps its own `build.yml`, and the Gradle repositories use one identical copy (see Decisions).
- Changing the shared workflows in this repository. That work belongs to the workflow changes already in progress.
- Auto-merging Renovate pull requests. Renovate only opens pull requests; people merge them.
- Migrating state to an S3 bucket. That is the fallback if HCP Terraform's free tier is exceeded (see Risks).

## Decisions

**Settings are managed by Terraform in `joke/workflows`, not by Probot.** The configuration lives in `terraform/` in `joke/workflows`. It uses the official `integrations/github` provider. The shared defaults live in one module (`terraform/modules/repository`). `terraform/repos.tf` reads each `terraform/repos/<name>.yaml` with `for_each` and passes its metadata and required checks to the module. A repository with an empty required-check list gets no required checks. Probot's `settings.yml` is removed from each repository during its cutover, because Probot and Terraform would otherwise both try to set the same values.

**HCP Terraform on the free tier runs the plan and apply.** The HCP Terraform workspace is connected to `joke/workflows` with working directory `terraform/`. It plans on pull requests and applies on merge to `main`. Terraform changes are applied automatically by HCP Terraform when a pull request that changes `terraform/` merges to `main`; nobody runs `terraform apply` by hand. Wherever this change says "apply" a Terraform entry, it means merging that entry's pull request and letting HCP Terraform apply it. The free tier allows up to 500 managed resources and one concurrent run. The estimated count is about three resources per repository, so it fits for the current set of repositories. If the cap is exceeded, state moves to an S3 bucket provided by the owner, and that is a separate change.

**The GitHub token is a sensitive workspace variable.** Terraform needs a token that can administer every managed repository. The token is stored as a sensitive variable in the HCP Terraform workspace, never in the repository. A GitHub App would avoid a personal token, but it needs installing and is left for a later change.

**`joke/workflows` is public, so it gets branch protection like every other repository.** It was private during this change, and the free plan returns HTTP 403 for protection on private repositories. It was made public so that protection, and the `pre-commit.ci` check, work there. Its history was checked for secrets before the change: none found. Its commits carry the author address `joke@xckk.de`, which is now public.

**Branch protection is a repository ruleset, not classic branch protection.** `github_branch_protection_v3` cannot set linear history, and it cannot tie a required check to an app ID in the same way a ruleset can. `github_repository_ruleset` sets linear history, the pull-request rules, and required checks with an `integration_id`, so each repository's checks name their app (`pre-commit.ci` 68672, `Semantic PR` 198092, `DCO` 1861). The ruleset has no bypass actors, so nobody can push to `main` directly, repository admins included. Every change goes through a pull request that passes the required checks. This replaces the admin bypass that matched the old `enforce_admins: false`; it was removed after a direct push to `main` on `joke/spock-deepmock`. Migrating a repository means removing its classic protection in the same apply; both would otherwise apply together.

**The shared defaults are the settings that are the same everywhere.** Merge methods, `delete_branch_on_merge`, `allow_auto_merge`, `allow_update_branch`, vulnerability alerts, automated security fixes, linear history, conversation resolution and `strict` status checks. Required checks are not in the shared defaults. They come from each repository's group, and each group uses one list:
- **zim modules:** `pre-commit.ci - pr`, `Semantic PR`, `DCO`.
- **Gradle libraries:** `pre-commit.ci - pr`, `Semantic PR` and `build`. DCO is dropped from this group, because it is not reported on several of these repositories. The CodeQL and codecov checks, and their workflows, are removed.
- **Metadata-only repositories** (`ktouch-noted`, `zmk-config`, `claude-plugins`, `dotfiles`): the shared merge and branch settings, with no required checks, because these repositories have no pipeline to report them.

The asdf plugin repositories (`asdf-kn`, `asdf-chezmoi`, `asdf-crossplane-cli`, `asdf-plugins`, `zim-asdf`) are archived and not managed. `zsh` was already archived. `template` was deleted.

**No required approvals, and auto-approval is removed.** The shared defaults set required approving reviews to 0, with code owner review off. With no approval required, the auto-approval workflows have no job left to do, so they are removed from every repository that has one: `autoapproval.yml` in the 17 `zim/zim-*` modules, `zim-fnox`, `zim-mise` (top level), `spock-mockable`, `spock-outputcapture` and `asdf-age-plugin-yubikey`. Removal happens only after Terraform has applied the 0 setting to that repository.

**Renovate preset lives in this repository at `renovate/default.json`.** Each repository has a `renovate.json` containing `"extends": ["github>joke/workflows//renovate/default"]` and nothing else. The preset was first created in a separate `joke/renovate-config` repository and moved here so there is one place for the policy. The preset sets:
- digest pinning off for GitHub Actions and reusable workflows, so both stay on version tags,
- grouping of GitHub Actions and Gradle updates,
- the Gradle ignore rules currently in `spock-deepmock`'s `dependabot.yml` (`groovy-bom` and `spock-bom` major and minor updates),
- automerge disabled for every update type.

**Automerge is off in Renovate, and owner auto-merge is removed for now.** Renovate's own automerge is disabled. The owner's auto-merge workflow is removed: `spock-deepmock/.github/workflows/automerge.yml`, and the uncommitted copy at `workflows/.github/workflows/automerge.yml`, which is already gone. Pull requests are merged by hand until auto-merge is reintroduced in a separate change.

**Shared workflows for every repository.** The build and the release of the Gradle libraries are reusable workflows in this repository, so every Gradle library runs the same steps:
- `.github/workflows/gradle-build.yml` runs `./gradlew check` with mise and a test report. The job is `build`, and the check name is `build / build`.
- `.github/workflows/gradle-release.yml` runs release-please, publishes releases to Maven Central, publishes releases to the Gradle Plugin Portal with `publishPlugins` when the project has that task, and publishes snapshots on other pushes to main. It takes an optional `tag` input to re-publish a failed release.
- `.github/workflows/zim-release.yml` runs release-please with the simple release type for the zim modules.

Each repository's `build.yml` and `release.yml` only call these workflows, with no inputs of their own. Repositories that need an extra job keep it in their own `release.yml`: `percolate` keeps its docs and deploy jobs. Codecov and CodeQL are removed. Repositories use mise for their toolchain, and a repository without a `.mise.toml` gets one with the Java version its build used before.

Release-please runs on the default `GITHUB_TOKEN`. Every repository allows GitHub Actions to create and approve pull requests, and its default workflow permissions are read and write. The `RELEASE_PLEASE` secret is not used and is deleted.

**Versioned shared workflows.** This repository releases with release-please (`release.yml`, version `1.0.0`, tag `v1.0.0` on main at the time of this change). Every repository pins the shared workflows to a tag (`@v1.0.0`), not to `@main`, so a change to the shared workflows reaches a repository only when that repository's pin moves. Renovate proposes the new tags as pull requests in each repository, and a person merges them. The preset turns digest pinning off for the `github-actions` manager, so reusable workflow refs stay on tags. Task 11.4 checks that Renovate proposes the next tag rather than a digest.

**Dependabot security alerts stay on.** Vulnerability alerts and automated security fixes stay enabled through Terraform. Only version updates move to Renovate.

**Repository secrets are managed by Terraform from one SOPS file.** `terraform/secrets.enc.yaml` holds the Maven Central set (`GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`, `GPG_FINGERPRINT`, `MAVENCENTRALUSERNAME`, `MAVENCENTRALPASSWORD`) and the Gradle Plugin Portal set (`GRADLE_PUBLISH_KEY`, `GRADLE_PUBLISH_SECRET`), encrypted for one age key (`.sops.yaml`). `terraform/secrets.tf` sets a `github_actions_secret` for every Java and Gradle plugin repository from that file. HCP Terraform decrypts with the age key in the `SOPS_AGE_KEY` environment variable of the workspace, which is never a Terraform variable. A precondition fails the plan while any value is still `CHANGE_ME`. Secret names are the ones the tools read directly, so no `ORG_GRADLE_PROJECT_*` aliases are used. Rotating a key means re-encrypting the file with `sops` and updating the values. Terraform cannot detect a value changed outside the file, and removal of unmanaged secrets is a separate, explicit step. The `OSSRH_*` secrets were removed once replaced.

**Rollout order.** Terraform is first applied to one zim module (`zim-mise`) and its settings are confirmed. Renovate is tested on `spock-deepmock` first, with its ignore rules ported into the preset. Then the Terraform entries and the preset are rolled out to the other repositories.

**Dependabot version updates.** The `dependabot.yml` removal is a file deletion in each repository. Terraform can delete a file it manages through `github_repository_file`, so the removal is part of each repository's Terraform entry, or a pull request if that does not work (verified in task 1.4).

Alternatives considered:
- **`_extends` in Probot:** tested and works for syntax, but cannot pin a version and does not re-sync children when the base changes.
- **A central fan-out workflow that opens pull requests in every repository:** needs a place to run and a token. Terraform's plan on pull requests covers the review step without a separate process.
- **Dependabot with a synced `dependabot.yml`:** rejected, because Renovate's preset gives one structure directly.

## Probe results (kept for reference)

The probe results below decided the change away from `_extends`:
- `_extends: workflows` (bare repository name) resolves. PR #29 merged with a throwaway base in `joke/workflows/.github/settings.yml` that sets only `web_commit_signoff_required: true`, and the setting synced to `true` on the repository.
- A check declared in both the base and the repository is deduplicated. PR #31 declared `DCO` in the base, which `zim-mise` already requires, and the result was one `DCO` entry alongside the repository's own `pre-commit.ci - pr` and `Semantic PR`.
- The repository's own scalar setting overrides the base's value. `web_commit_signoff_required: false` in `zim-mise` overrode the base's `true`.
- A check that appears only in the base was not tested. It would have blocked PRs on `zim-mise`.

## Risks / Trade-offs

- **HCP Terraform free tier cap.** → Estimated at about three managed resources per repository. If the 500-resource cap is exceeded, move state to the owner's S3 bucket in a separate change.
- **Terraform and Probot both managing settings.** → Probot's `settings.yml` is removed from each repository as part of its cutover, before that repository's Terraform entry is applied.
- **A token with administrative rights.** → Stored only as a sensitive HCP Terraform variable. Scope it to the managed repositories.
- **Renovate silently disables an update type that a repository needs.** → Repositories that need an update type add a local `packageRules` entry with `enabled: true`. The preset is checked with `renovate-config-validator` before publishing.
- **Renovate onboarding opens a pull request in every repository.** → That is expected. Each onboarding PR is reviewed like any other.
- **The preset is in the public `joke/workflows` repository, so the policy is visible.** → The policy contains no secrets, so visibility is acceptable.
- **Loss of Dependabot's version-update behavior during the switch.** → Renovate is enabled on one repository first, and Dependabot's `dependabot.yml` is removed only after the Renovate PRs there have been reviewed.

## Migration Plan

1. Verify the HCP Terraform free tier: the managed-resource count, VCS-driven plans on pull requests, and the provider resources the design uses.
2. Write `terraform/` in `joke/workflows` with the shared module and the `zim-mise` entry. Import the existing `zim-mise` resources and confirm the plan shows only the intended changes.
3. Remove `zim-mise`'s `settings.yml`, merge the Terraform entry's pull request (HCP Terraform applies it), and confirm its settings and approvals match.
4. Create `joke/renovate-config` with `default.json`, and validate it.
5. Enable Renovate on `spock-deepmock`, port its ignore rules, review the first pull requests, then remove its `dependabot.yml`.
6. Roll out the Terraform entries and the Renovate preset to the remaining repositories, one repository type at a time.
7. Remove `.github/settings.yml` from `joke/workflows`, which holds the throwaway probe and is not used by Terraform.

Rollback: restore the repository's previous `.github/settings.yml` and `.github/dependabot.yml`, and remove its `renovate.json` and its Terraform entry. Apply the Terraform removal to return the repository to its previous settings.

## Open Questions

- Whether the HCP Terraform VCS integration is available on the free tier for this repository. Checked in task 1.1.
