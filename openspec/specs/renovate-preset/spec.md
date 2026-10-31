# renovate-preset Specification

## Purpose
Defines the shared Renovate preset that every managed repository extends, so that dependency updates follow one policy: they are proposed as pull requests and merged by a person.

## Requirements

### Requirement: Every managed repository extends the shared preset
Each managed repository SHALL have a `renovate.json` that extends `github>joke/workflows//renovate/default` and sets nothing else.

#### Scenario: Repository configured
- **WHEN** Renovate reads a managed repository's `renovate.json`
- **THEN** the policy comes from the shared preset

### Requirement: Renovate never merges automatically
The preset SHALL disable automerge for every update type. A dependency update SHALL be merged only by a person.

#### Scenario: Update proposed
- **WHEN** Renovate opens a dependency update pull request
- **THEN** the pull request stays open until a person merges it

### Requirement: GitHub Actions and reusable workflows are pinned to tags
The preset SHALL disable digest pinning for the GitHub Actions manager, so that action and reusable workflow references stay on version tags.

#### Scenario: Action update
- **WHEN** Renovate proposes an update to an action or a reusable workflow
- **THEN** the proposed reference is a tag, not a commit digest

### Requirement: Gradle updates are grouped
The preset SHALL group the Gradle updates of a repository into one pull request, and the GitHub Actions updates into another.

#### Scenario: Several Gradle updates
- **WHEN** Renovate has several Gradle updates for one repository
- **THEN** they are proposed in one group

### Requirement: Groovy and Spock BOM major and minor updates are ignored
The preset SHALL disable major and minor updates of `org.codehaus.groovy:groovy-bom` and `org.spockframework:spock-bom`.

#### Scenario: Spock BOM minor update
- **WHEN** a minor version of the Spock BOM is released
- **THEN** Renovate does not propose it
