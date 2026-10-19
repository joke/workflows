# Tasks

## 1. Decisions and checks

- [x] 1.1 Decide the required approving review count for the shared settings. Decided as 0 with code owner review off, recorded in design.md.
- [x] 1.2 Verify the Probot `_extends` syntax and how required checks merge. Done with a throwaway base; outcome recorded in design.md. Superseded as a distribution method by Terraform (see design.md, Probe results).
- [x] 1.3 Verify the HCP Terraform free tier for this repository: the 500 managed-resource cap, VCS-connected plans on pull requests, and applies on merge to `main`. Plan on pull request verified: workspace `xckk/workflows-settings` is VCS-connected to `joke/workflows` (working directory `terraform/`), and PR joke/workflows#1 shows a passing `Terraform Cloud/xckk/...` check. Apply on merge is not yet verified; it is covered by task 2.5. The 500-resource cap is not yet checked against the real resource count; it is checked when the zim modules are added.
- [x] 1.4 Verify the `integrations/github` provider resources the design uses: `github_repository`, branch protection, `github_repository_dependabot_security_updates`, vulnerability alerts, and `github_repository_file` deleting a file when its resource is removed. Verified when a throwaway plan against one repository shows each resource and the file deletion behaves as described.
  - Schema check done (provider 6.x, from `terraform providers schema -json`):
    - Required checks with an app ID exist only on `github_branch_protection_v3`, as `context:app_id` strings. The current `github_branch_protection` has only plain `contexts`, so the design needs v3.
    - Vulnerability alerts are `github_repository_vulnerability_alerts`, and automated security fixes are `github_repository_dependabot_security_updates`. Both are separate resources.
    - `github_repository` covers the merge settings and `delete_branch_on_merge`.
  - File deletion checked in provider source (`resource_github_repository_file.go`): removing the resource calls `DeleteFile`, which commits the deletion to the resource's `branch`, defaulting to `main`. Open risk: if `main` requires a pull request (as it will with required reviews set), that commit may be refused. Test it with a throwaway repo before relying on it.
  - Live test on the throwaway repo `joke/tf-probe-1-4` (public, protected `main` with 0 required reviews, linear history, conversation resolution and strict checks, `enforce_admins` off):
    - Creating a `github_repository_file` on the protected `main` succeeded. The token is an owner token with admin rights, so the protection was bypassed.
    - Removing the resource deleted the file, with a commit. The commit message is "Delete .github/dependabot.yml" only when the resource uses the default `commit_message`. A custom message is reused for the deletion, so leave `commit_message` unset.
    - Not tested: a token that is not an admin. If the HCP token has no bypass, the create and delete commits may be refused on the protected `main`. The token scope is part of the HCP setup in task 2.1.
  - Clean-up: the throwaway repo `joke/tf-probe-1-4` still exists. Delete it when you're ready.

## 2. Terraform configuration

- [x] 2.1 Create `terraform/` in `joke/workflows` with the provider configuration, the HCP Terraform backend, and the token as a sensitive workspace variable. Verified when `terraform init` and `terraform validate` pass locally.
- [x] 2.2 Write the shared module (`terraform/modules/repository`) with the defaults from design.md. Branch protection is a repository ruleset, as decided in design.md, because `github_branch_protection_v3` can't set linear history. Validated with `terraform validate`; PR joke/workflows#2 (not merged). Defaults: merge methods, delete-branch-on-merge, auto-merge, update-branch, vulnerability alerts, automated security fixes, linear history, conversation resolution, `strict` status checks, and zero approvals with code owner review off. Verified when `terraform validate` passes and the module has no per-repository identity.
- [x] 2.3 Add the `zim-mise` entry (written in `terraform/repos.tf` on PR joke/workflows#2; pending the HCP plan on that PR) with its name, description, topics and required checks (`pre-commit.ci - pr`, `Semantic PR`, `DCO`). Verified when the plan shows no change to its name, description, topics or checks.
- [x] 2.4 Import the existing `zim-mise` resources into the state. Verified when the plan shows only the intended changes: approvals from 1 to 0, and code owner review from on to off. Done: the classic protection was imported and removed by PR #5, and `zim-mise` now reports `Branch not protected`.
- [ ] 2.5 Connect the HCP Terraform workspace to `joke/workflows` with working directory `terraform/`, plan on pull requests, and apply on merge to `main`. Verified when a test pull request shows a plan comment and merging it runs an apply.
- [ ] 2.6 (in progress, PR joke/workflows#6) Apply branch protection to `joke/workflows` like every other repository. It was excluded while the repository was private, because the free plan returns HTTP 403 for protection on private repos; it has been public since this change. Verified when the plan for `joke/workflows` includes its protection resource and the apply succeeds.

## 3. Renovate preset

- [x] 3.1 Create the public repository `joke/renovate-config` with `default.json` containing the policy in design.md, including the Gradle ignore rules and automerge disabled. Verified when `renovate-config-validator` passes on the file. Done: `joke/renovate-config` is public; `default.json` validates. The ignore rules use the full coordinates `org.codehaus.groovy:groovy-bom` and `org.spockframework:spock-bom`.
- [x] 3.1b Move the preset into this repository at `renovate/default.json` (PR joke/workflows#7), and delete `joke/renovate-config`. The repository is deleted. The preset path `github>joke/workflows//renovate/default` is not yet checked with `renovate-config-validator`; that check is pending.
- [ ] 3.2 Install the Renovate GitHub App for the account with access to the repositories being migrated. Verified when the app is listed under the account's installed GitHub Apps.

## 4. Pilot on zim-mise and spock-deepmock

- [ ] 4.1 Remove `zim-mise`'s `.github/settings.yml` and apply its Terraform entry. Verified when Probot no longer syncs the repository, Terraform's plan is empty, and the repository's approvals read 0.
- [~] 4.2 (renovate.json added in PR joke/spock-deepmock#248, merged; onboarding PR waits for the Renovate app, task 3.2) Add `renovate.json` to `spock-deepmock` containing only `"extends": ["github>joke/renovate-config"]`. Verified when Renovate's onboarding PR appears and validates.
- [ ] 4.3 Add the `spock-deepmock` entry to Terraform and remove its `.github/settings.yml`. Verified when its plan keeps its own required checks and its settings match the shared defaults.
- [ ] 4.4 Review the first Renovate pull requests in `spock-deepmock`, and confirm no update is auto-merged. Verified when each Renovate PR is open until a person merges it.
- [x] 4.5 (superseded by 10.2, removed with the other repositories) Remove `spock-deepmock`'s `.github/dependabot.yml` after the Renovate pull requests have been reviewed. Verified when the file is gone and Renovate still opens version-update PRs.
- [x] 4.6 Remove `spock-deepmock`'s `.github/workflows/automerge.yml`. Done in joke/spock-deepmock#248. Verified when the file is gone and a new PR from the owner is not auto-merged.

## 5. Auto-approval and owner auto-merge removal

- [x] 5.1 Remove `workflows/.github/workflows/automerge.yml` (uncommitted, created earlier in this change's parent work). Verified when the file is gone and `git status` no longer lists it.
- [ ] 5.2 Remove `.github/workflows/autoapproval.yml` from `asdf-age-plugin-yubikey`, `spock-mockable`, `spock-outputcapture`, `zim-fnox` and `zim-mise` (top level). Verified when each file is gone and each repository's required approvals in its settings are 0 according to Terraform. Do this only after step 4.1 has applied to that repository.
- [ ] 5.3 Remove `.github/workflows/autoapproval.yml` from the 17 `zim/zim-*` modules, one at a time, each after its Terraform entry has applied. Verified when each file is gone and each repository's required approvals in its settings are 0.

## 6. Rollout

- [ ] 6.1 Add Terraform entries for the remaining zim modules, one at a time. For each: remove its `settings.yml`, apply, and confirm its required checks. Verified when every module's settings match the shared defaults and its `dependabot.yml` is removed.
- [ ] 6.2 Add Terraform entries and the Renovate preset to the remaining repositories, one repository type at a time. Verified when every repository is listed in Terraform and extends the preset in its `renovate.json`.
- [ ] 6.3 (in progress, PR joke/workflows#6: `.github/settings.yml` removed, `joke/workflows` managed by `terraform/repos/workflows.yaml`) Remove `.github/settings.yml` from `joke/workflows`, which holds the throwaway probe and is not used by Terraform. Verified when the file is gone and the Terraform plan for `joke/workflows` is unchanged.

## 7. Group onboarding

Each repository gets a YAML file under `terraform/repos/`, and its `settings.yml` is removed in its own PR. Its classic branch protection is imported and removed through the module's `legacy_protection` toggle. Required checks come from its group (see design.md).

- [ ] 7.1 Merge PR joke/workflows#6, which reads repository metadata from `terraform/repos/*.yaml` with `for_each`. The plan has no changes beyond the `zim-mise` state move.
- [x] 7.2 zim modules (16 repositories; done: settings.yml removed, Terraform entries applied, classic protection removed, autoapproval.yml removed from 15): remove `.github/settings.yml`, add YAML entries with the zim check list, import and remove the classic protection, then remove `.github/workflows/autoapproval.yml` after the apply. `zim-rtx` is a fork and is excluded.
- [x] 7.3 Gradle libraries (`spock-deepmock`, `spock-mockable`, `spock-outputcapture`, `spring-factory`, `objects`, `lint-rules`, `percolate`, `caffeinate`, `jspecify`, `conventional-version`): done. settings.yml removed, Terraform entries applied (joke/workflows#10), classic protection removed. CodeQL and codecov removed from `spock-mockable` and `objects`; autoapproval.yml removed from `spock-mockable` and `spock-outputcapture` (PRs #385, #50, #226). Required checks: `pre-commit.ci - pr`, `Semantic PR`, `build`. DCO is dropped from this group. Still open: `spock-deepmock`'s `automerge.yml` is kept for the Renovate pilot (task 4.6).
- [ ] 7.4 Metadata-only repositories (`ktouch-noted`, `zmk-config`, `claude-plugins`, `dotfiles`, `vpn2`, `vpn`): add YAML entries with no required checks, remove `.github/settings.yml` where present, and remove any classic protection. `vpn2` uses the description of `vpn`.
- [ ] 7.5 Renovate and Dependabot for the groups above are not part of this section. They wait on tasks 3.2 and 4.x.

## 8. Unified build workflow

- [x] 8.1 (superseded by 8.6: the workflow is now shared, not copied) Copy `.github/workflows/build.yml` from `lint-rules` into each Gradle library (`spock-deepmock`, `spock-mockable`, `spock-outputcapture`, `spring-factory`, `objects`, `percolate`, `caffeinate`, `jspecify`, `conventional-version`). Remove the Codecov steps. The check name stays `build`.
- [ ] 8.2 Add a `.mise.toml` with the Java version the build used before to `spock-mockable`, `spring-factory` and `objects`, which have none.
- [ ] 8.3 Remove `codeql-analysis.yml` wherever it still exists.
- [ ] 8.4 Check `build` on every Gradle library after the change. `conventional-version` (PR joke/conventional-version#21) fails PMD on `UnnecessaryWarningSuppression`; left as is until its Gradle build is reviewed separately. Check `spock-deepmock`'s example-test matrix, which the copied workflow doesn't run, and decide whether it needs its own job.
- [x] 8.6 One shared workflow: `.github/workflows/gradle-build.yml` in joke/workflows (PR #12), with no inputs. Each Gradle library's `build.yml` only calls it (PRs spock-deepmock#256, spock-mockable#387, spock-outputcapture#228, spring-factory#154, objects#52, lint-rules#12, percolate#89, caffeinate#38, jspecify#18 merged; conventional-version#22 open and failing). The required check is `build / build` (joke/workflows#13).
- [x] 8.5 Dependabot: close all open Dependabot PRs in the in-scope repositories (78 closed).

## 9. Release workflows

- [x] 9.1 Reusable `gradle-release.yml` (release-please, Maven Central publish, snapshots) and `zim-release.yml` (release-please, simple) in joke/workflows (PR #14).
- [x] 9.2 Each library's and zim module's `release.yml` calls the shared workflow (PRs merged, 25 repositories). `percolate` keeps its docs and deploy jobs. `conventional-version` drops its `verify` and `fidelity` jobs. `caffeinate` gets a new `release.yml`.
- [x] 9.3 Release-please config and manifest copied into `spock-mockable`, `spock-outputcapture`, `spring-factory`, `objects` and `caffeinate`.
- [x] 9.4 zim-release runs without a token (joke/workflows#15). `RELEASE_PLEASE` is deleted from every repository.
- [ ] 9.5 Gradle secrets (set by the owner): `lint-rules`, `spock-deepmock`, `percolate` and `jspecify` have the Maven Central secrets. `spock-mockable`, `spock-outputcapture` and `spring-factory` need `GPG_FINGERPRINT` and `GPG_PASSPHRASE`, and their Gradle publish tasks. `objects` and `caffeinate` have no GPG or Maven secrets. `conventional-version` uses `GRADLE_PUBLISH_*` instead of the Maven Central secrets. `zim-fnox` has no secrets. `caffeinate`'s release-please config fails to parse, and it needs Actions to create pull requests.

## 10. Repository settings and cleanup

- [x] 10.1 Every in-scope repository: default workflow permissions read and write, and GitHub Actions may create and approve pull requests.
- [x] 10.2 `.github/dependabot.yml` and `.github/autoapproval.yml` removed from every in-scope repository (PRs merged, `zim-krew` had no dependabot file).
- [x] 10.3 Dependabot PRs closed (78) in the in-scope repositories.

## 11. Versioned shared workflows

- [x] 11.1 Tag `v1.0.0` on joke/workflows main (d19d946), the baseline for release-please.
- [x] 11.2 Merge joke/workflows#17: release-please for this repository is merged. The release job ran on main and opened no release PR, as expected, since no feat or fix commit has landed since v1.0.0.: release-please for this repository (`release.yml`, `release-please-config.json`, `.release-please-manifest.json` at 1.0.0) and the rewritten README. Delete the untracked root copies of these files from the local checkout before pulling.
- [x] 11.3 (25 of 26 merged; `conventional-version#25` is blocked by its PMD failure) Pin every caller (`build.yml` and `release.yml` in the Gradle libraries and zim modules, and `percolate`'s `release.yml`) from `@main` to `@v1.0.0`.
- [ ] 11.4 Check that Renovate detects the pinned reusable workflow refs (`uses: joke/workflows/.github/workflows/...@v1.0.0`) and proposes the next tag. The preset disables digest pinning for GitHub Actions, so no separate exception is planned; this run confirms it.
- [x] 11.5 Replace the digest pins on `jdx/mise-action` in `gradle-build.yml` and `gradle-release.yml` with the `v5` tag. Renovate's digest pin was reverted in the preset but not in the workflows. Verified when the workflows reference `@v5` and no digest.

## Workflow follow-up

- Archive this change after the rollout is verified, with `/opsx:archive`.
