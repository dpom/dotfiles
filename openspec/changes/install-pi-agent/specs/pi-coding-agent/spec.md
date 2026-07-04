# pi-coding-agent

## Purpose

Install and configure the pi coding agent CLI (`@earendil-works/pi-coding-agent`) at a specific version on NixOS hosts via Home Manager.

## Requirements

### Requirement: Pi CLI availability
The system SHALL make the `pi` binary available in the user's PATH when the module is enabled.

#### Scenario: Module enabled, pi in PATH
- **GIVEN** `dpom-pi.enable = true` on a host
- **WHEN** the user runs `pi --version` in a shell
- **THEN** the `pi` binary SHALL be found and executable
- **THEN** the version SHALL be `0.80.3`

#### Scenario: Module disabled, pi not available
- **GIVEN** `dpom-pi.enable = false` (default)
- **WHEN** the user runs `which pi` or `command -v pi`
- **THEN** `pi` SHALL NOT be found in PATH

### Requirement: Package version pinned
The module SHALL build pi from source using `pkgs.buildNpmPackage` at the exact upstream tag `v0.80.3`.

#### Scenario: Version matches upstream tag
- **WHEN** the `pi-coding-agent` package is built
- **THEN** the source SHALL be fetched from `github:earendil-works/pi` at tag `v0.80.3`
- **THEN** the resulting `pi` binary SHALL report version `0.80.3` with `pi --version`

### Requirement: Module follows dpom pattern
The module SHALL use the standard `dpom-pi.enable` option pattern.

#### Scenario: Module togglable per host
- **WHEN** `dpom-pi.enable = true` is set in `hosts/mary/home.nix` and `hosts/bob/home.nix`
- **THEN** `pi` SHALL be available on both mary and bob
- **WHEN** `dpom-pi.enable = false` (default) on a host
- **THEN** `pi` SHALL NOT be installed on that host

### Requirement: Org-mode source management
The module and its enable toggle SHALL be defined in `Config.txt` and tangled to the generated `.nix` files.

#### Scenario: Module defined in literate Org
- **WHEN** the module is created
- **THEN** the module definition SHALL be added to `Config.txt` (not edited directly in `modules/home/pi.nix`)
- **THEN** `ent generate` or `./bin/generate-admin` SHALL tangle the module into place
- **THEN** both the `Config.txt` source and the generated `.nix` files SHALL be committed
