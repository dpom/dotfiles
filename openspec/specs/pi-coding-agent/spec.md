# pi-coding-agent

## Purpose

Install and configure the pi coding agent CLI (`@earendil-works/pi-coding-agent`) and ACP adapter (`pi-acp`) at specific versions on NixOS hosts via Home Manager, with pre-configured Ollama provider presets.

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

### Requirement: pi-acp companion package
The module SHALL also install the `pi-acp` ACP adapter at v0.0.31 alongside `pi-coding-agent`.

#### Scenario: pi-acp in PATH when enabled
- **GIVEN** `dpom-pi.enable = true` on a host
- **WHEN** the user runs `pi-acp --version`
- **THEN** the `pi-acp` binary SHALL be found and executable
- **WHEN** `dpom-pi.enable = false`
- **THEN** `pi-acp` SHALL NOT be in PATH

### Requirement: Dynamic Ollama provider presets
The module SHALL dynamically generate `.pi/agent/models.json` at activation time by querying the local Ollama instance for available models.

#### Scenario: models.json generated from Ollama
- **GIVEN** `dpom-pi.enable = true`
- **WHEN** `home-manager switch` runs
- **THEN** the activation hook SHALL query `http://localhost:11434/api/tags`
- **THEN** each returned model SHALL be added to the `providers.ollama.models` array with `contextWindow: 65536` and `maxTokens: 32768`
- **THEN** if Ollama is unreachable, an empty model list SHALL be written

#### Scenario: Template preserved
- **GIVEN** `dpom-pi.enable = true`
- **WHEN** `~/.pi/agent/models.json` is generated
- **THEN** the ollama provider config (`baseUrl`, `api`, `apiKey`, `compat`) SHALL be preserved from the static template
- **THEN** only the `models` array SHALL be dynamically populated

### Requirement: Package versions pinned
The module SHALL build both packages from source using `pkgs.buildNpmPackage` at exact upstream tags.

#### Scenario: Version matches upstream tag
- **WHEN** the `pi-coding-agent` package is built
- **THEN** the source SHALL be fetched from `github:earendil-works/pi` at tag `v0.80.3`
- **THEN** the resulting `pi` binary SHALL report version `0.80.3` with `pi --version`
- **WHEN** the `pi-acp` package is built
- **THEN** the source SHALL be fetched from `github:svkozak/pi-acp` at tag `v0.0.31`

### Requirement: Module follows dpom pattern
The module SHALL use the standard `dpom-pi.enable` option pattern.

#### Scenario: Module togglable per host
- **WHEN** `dpom-pi.enable = true` is set in `hosts/mary/home.nix` and `hosts/bob/home.nix`
- **THEN** both `pi` and `pi-acp` SHALL be available on both mary and bob
- **WHEN** `dpom-pi.enable = false` (default) on a host
- **THEN** neither `pi` nor `pi-acp` SHALL be installed on that host

### Requirement: Org-mode source management
The module and its enable toggle SHALL be defined in `Config.txt` and tangled to the generated `.nix` files.

#### Scenario: Module defined in literate Org
- **WHEN** the module is created
- **THEN** the module definition SHALL be added to `Config.txt` (not edited directly in `modules/home/pi.nix`)
- **THEN** `ent generate` or `./bin/generate-admin` SHALL tangle the module into place
- **THEN** both the `Config.txt` source and the generated `.nix` files SHALL be committed
