# shared-gradle-workflows Specification

## Purpose
Defines the reusable build and release workflows that every Gradle library and Gradle plugin repository calls, so that the build check and the release path are the same everywhere.

## Requirements

### Requirement: The build check is named build / build
The shared build workflow SHALL run `./gradlew check` with the repository's mise toolchain, and its job SHALL be named `build`, so the required check is `build / build`.

#### Scenario: Pull request build
- **WHEN** a pull request is opened against a Gradle library
- **THEN** the check `build / build` runs `./gradlew check`

### Requirement: Releases are cut by release-please
The shared Gradle release workflow SHALL run release-please on every push to `main`. A release SHALL be cut only when release-please reports one.

#### Scenario: Push without a release
- **WHEN** a push to `main` does not cut a release
- **THEN** no artifact is published to Maven Central

### Requirement: A release is published to Maven Central
When release-please cuts a release, the workflow SHALL publish the release to Maven Central with the Maven Central credentials, signed with the GPG key.

#### Scenario: Release cut
- **WHEN** release-please cuts a release
- **THEN** the release is published to Maven Central and signed

#### Scenario: Re-publish
- **WHEN** the workflow is started manually with a `tag` input
- **THEN** that tag is published again

### Requirement: Snapshots are published from main
On every push to `main` that does not cut a release, the workflow SHALL publish a snapshot to Maven Central. A release commit SHALL NOT publish a snapshot.

#### Scenario: Ordinary push
- **WHEN** a push to `main` does not cut a release
- **THEN** a snapshot is published

#### Scenario: Release commit
- **WHEN** a push cuts a release
- **THEN** only the release is published, and no snapshot

### Requirement: The Gradle Plugin Portal receives releases of plugins
When a release is cut, the workflow SHALL run `publishPlugins` with the Gradle Plugin Portal credentials if the project has that task. Projects without the task SHALL skip the step. The portal SHALL NOT receive snapshots.

#### Scenario: Gradle plugin project
- **WHEN** a release is cut and the project has `publishPlugins`
- **THEN** the plugin is published to the Gradle Plugin Portal

#### Scenario: Library project
- **WHEN** a release is cut and the project has no `publishPlugins` task
- **THEN** the portal step is skipped and the release succeeds

#### Scenario: Snapshot
- **WHEN** a snapshot is published
- **THEN** the portal step does not run

### Requirement: Repositories pin the shared workflows to a tag
A repository SHALL call the shared workflows at a version tag, not at `main`, so that a change to the shared workflows reaches it only when its pin moves.

#### Scenario: Caller pinned
- **WHEN** a repository's `build.yml` or `release.yml` calls a shared workflow
- **THEN** the reference names a tag such as `@v1.0.1`

### Requirement: Shared workflows take no inputs from the caller
Each repository's `build.yml` and `release.yml` SHALL call the shared workflow with no inputs of its own, except the optional `tag` input of the release.

#### Scenario: Caller
- **WHEN** a repository calls the shared release workflow
- **THEN** it passes secrets with `secrets: inherit` and no other input
