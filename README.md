# workflows

Reusable GitHub Actions workflows and the Renovate preset shared by my repositories.

## Workflows

| File | Purpose | Input | Secrets |
| --- | --- | --- | --- |
| `.github/workflows/gradle-build.yml` | `./gradlew check` with mise and a test report. Job `build`, check `build / build`. | none | none |
| `.github/workflows/gradle-release.yml` | release-please, Maven Central publish, snapshots. | `tag` (optional, re-publish a failed release) | `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`, `GPG_FINGERPRINT`, `mavenCentralUsername`, `mavenCentralPassword` |
| `.github/workflows/zim-release.yml` | release-please with the simple release type for zim modules. | none | none |

Repositories call these with a small `build.yml` and `release.yml`, pinned to a version tag:

```yaml
jobs:
  build:
    uses: joke/workflows/.github/workflows/gradle-build.yml@v1.0.0
```

## Versions

Every release of this repository is a tag `vX.Y.Z`, created by release-please from `release.yml`. A
repository pins the workflows to one tag; Renovate proposes newer tags as pull requests there, and
a person merges them.

## Renovate preset

`renovate/default.json` is the shared preset. A repository extends it from its `renovate.json`:

```json
{ "extends": ["github>joke/workflows//renovate/default"] }
```

## Release-please

`release-please-config.json` and `.release-please-manifest.json` describe this repository as one
package at version `1.0.0`. The first release after that is cut from the commits that follow the
`v1.0.0` tag.
