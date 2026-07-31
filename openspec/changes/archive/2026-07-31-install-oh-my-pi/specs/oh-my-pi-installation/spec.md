## ADDED Requirements

### Requirement: omp CLI availability
Feature: oh-my-pi-installation
Rule: The system SHALL make the `omp` binary available in the user's PATH when the module is enabled.

#### Scenario: Module enabled, omp in PATH
- **GIVEN** `dpom-oh-my-pi.enable = true` on a host
- **WHEN** the user runs `omp --version` in a shell
- **THEN** the `omp` binary SHALL be found and executable

#### Scenario: Module disabled, omp not available
- **GIVEN** `dpom-oh-my-pi.enable = false` (default)
- **WHEN** the user runs `which omp` or `command -v omp`
- **THEN** `omp` SHALL NOT be found in PATH

### Requirement: Package built from source
Feature: oh-my-pi-installation
Rule: The module SHALL build oh-my-pi from source using `pkgs.buildNpmPackage` at a pinned upstream version.

#### Scenario: Version matches upstream tag
- **WHEN** the `oh-my-pi` package is built
- **THEN** the source SHALL be fetched from `github:can1357/oh-my-pi` at a specific tag
- **THEN** the resulting `omp` binary SHALL report a valid version with `omp --version`

### Requirement: Module follows dpom pattern
Feature: oh-my-pi-installation
Rule: The module SHALL use the standard `dpom-oh-my-pi.enable` option pattern.

#### Scenario: Module togglable per host
- **WHEN** `dpom-oh-my-pi.enable = true` is set in `hosts/mary/home.nix` and `hosts/bob/home.nix`
- **THEN** `omp` SHALL be available on both mary and bob
- **WHEN** `dpom-oh-my-pi.enable = false` (default) on a host
- **THEN** `omp` SHALL NOT be installed on that host

### Requirement: Coexistence with existing Pi
Feature: oh-my-pi-installation
Rule: The oh-my-pi module SHALL coexist with the existing Pi module without conflicts.

#### Scenario: Both modules enabled
- **GIVEN** `dpom-pi.enable = true` AND `dpom-oh-my-pi.enable = true` on a host
- **WHEN** the user runs `pi --version` and `omp --version`
- **THEN** both binaries SHALL be found and executable
- **THEN** their config directories SHALL be separate (`~/.pi/agent/` vs `~/.omp/agent/`)

### Requirement: Org-mode source management
Feature: oh-my-pi-installation
Rule: The module and its enable toggle SHALL be defined in `Config.txt` and tangled to the generated `.nix` files.

#### Scenario: Module defined in literate Org
- **WHEN** the module is created
- **THEN** the module definition SHALL be added to `Config.txt` (not edited directly in `modules/home/oh-my-pi.nix`)
- **THEN** `ent generate` or `./bin/generate-admin` SHALL tangle the module into place
- **THEN** both the `Config.txt` source and the generated `.nix` files SHALL be committed
