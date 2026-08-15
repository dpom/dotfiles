# Delta Spec: pi-coding-agent

## MODIFIED Requirements

### Requirement: Pi CLI availability
The system SHALL make the `pi` binary available in the user's PATH when the module is enabled.

#### Scenario: Module enabled, pi in PATH
- **GIVEN** `dpom-pi.enable = true` on a host
- **WHEN** the user runs `pi --version` in a shell
- **THEN** the `pi` binary SHALL be found and executable
- **THEN** the version SHALL be `0.84.2`

#### Scenario: Module disabled, pi not available
- **GIVEN** `dpom-pi.enable = false` (default)
- **WHEN** the user runs `which pi` or `command -v pi`
- **THEN** `pi` SHALL NOT be found in PATH

### Requirement: pi-acp companion package
The module SHALL also install the `pi-acp` ACP adapter at v0.0.33 alongside `pi-coding-agent`.

#### Scenario: pi-acp in PATH when enabled
- **GIVEN** `dpom-pi.enable = true` on a host
- **WHEN** the user runs `pi-acp --version`
- **THEN** the `pi-acp` binary SHALL be found and executable
- **WHEN** `dpom-pi.enable = false`
- **THEN** `pi-acp` SHALL NOT be in PATH

### Requirement: Package versions pinned
The module SHALL build both packages from source using `pkgs.buildNpmPackage` at exact upstream tags.

#### Scenario: Version matches upstream tag
- **WHEN** the `pi-coding-agent` package is built
- **THEN** the source SHALL be fetched from `github:earendil-works/pi` at tag `v0.84.2`
- **THEN** the resulting `pi` binary SHALL report version `0.84.2` with `pi --version`
- **WHEN** the `pi-acp` package is built
- **THEN** the source SHALL be fetched from `github:svkozak/pi-acp` at tag `v0.0.33`

## ADDED Requirements

### Requirement: Hermetic build compiles the telemetry workspace
Feature: pi-coding-agent
Rule: The `pi-coding-agent` build SHALL compile the `@earendil-works/pi-telemetry` workspace (`packages/telemetry`) before compiling `@earendil-works/pi-ai`, so that `packages/ai` resolves the `@earendil-works/pi-telemetry` type declarations during the hermetic Nix build.

#### Scenario: Build succeeds with telemetry compiled first
- **GIVEN** the `pi-coding-agent` package is being built from the v0.84.2 source
- **WHEN** the build phase compiles the pi monorepo workspaces
- **THEN** `npx tsgo -p packages/telemetry/tsconfig.build.json` SHALL run before `npx tsgo -p packages/ai/tsconfig.build.json`
- **THEN** the `packages/ai` compile SHALL resolve `@earendil-works/pi-telemetry` without error
- **THEN** the resulting `pi` binary SHALL build successfully under `ent update-home`

#### Scenario: Vendored model data matches pinned version
- **GIVEN** the `pi-coding-agent` package is built at v0.84.2
- **WHEN** the build applies the model data patch
- **THEN** a vendored snapshot SHALL exist at `modules/home/pi-model-data/0.84.2/`
- **THEN** the snapshot SHALL contain `.manifest.json` and the provider model data JSON files
