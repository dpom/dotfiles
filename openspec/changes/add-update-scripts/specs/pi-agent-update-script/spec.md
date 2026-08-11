## ADDED Requirements

### Requirement: Pi agent latest release resolution
The `bin/update-pi` script SHALL resolve the latest stable release of both pinned pi components from GitHub: `earendil-works/pi` (for `pi-coding-agent`) and `svkozak/pi-acp`.

#### Scenario: Latest releases resolved independently
- **GIVEN** the script is run
- **WHEN** it queries GitHub for the latest releases
- **THEN** the latest tag for `earendil-works/pi` SHALL be resolved
- **AND** the latest tag for `svkozak/pi-acp` SHALL be resolved independently
- **AND** both resolved versions SHALL be reported to the user

#### Scenario: Already at the latest versions
- **GIVEN** `modules/home/pi.nix` already pins the latest versions of both components
- **WHEN** the script is run
- **THEN** the script SHALL report that pi is already up to date
- **AND** SHALL NOT modify any files

### Requirement: Pi agent pin update in Org source
Running `bin/update-pi` SHALL update the pinned version, source hash, and `npmDepsHash` for both `pi-coding-agent` and `pi-acp` in the pi module definition inside `Config.txt`, then re-tangle so `modules/home/pi.nix` is regenerated.

#### Scenario: Both package pins updated
- **GIVEN** a newer release of `earendil-works/pi` and/or `svkozak/pi-acp` exists
- **WHEN** the script updates the pins
- **THEN** the `pi-coding-agent` version, source hash, and `npmDepsHash` SHALL match the resolved `earendil-works/pi` release
- **THEN** the `pi-acp` version, source hash, and `npmDepsHash` SHALL match the resolved `svkozak/pi-acp` release
- **THEN** the pi module block in `Config.txt` SHALL reflect the updated values

#### Scenario: Module regenerated after update
- **GIVEN** the script has updated the pi module block in `Config.txt`
- **WHEN** the script finishes its edits
- **THEN** `./bin/generate-admin` SHALL re-tangle `modules/home/pi.nix`
- **THEN** the regenerated `modules/home/pi.nix` SHALL be consistent with the updated `Config.txt`

#### Scenario: Existing module structure preserved
- **GIVEN** the pi module
- **WHEN** the update script changes the pinned versions
- **THEN** the `dpom-pi` module structure and options (enable toggle, config generation activation) SHALL remain unchanged

### Requirement: Hash correctness for updated pi pins
The script SHALL compute hashes that match how the pi packages are fetched, so the regenerated module builds without manual hash edits.

#### Scenario: Source hash matches fetchFromGitHub
- **GIVEN** the script has resolved a new `earendil-works/pi` or `svkozak/pi-acp` release
- **WHEN** it computes the source hash
- **THEN** the hash SHALL correspond to the GitHub archive tarball at tag `v<version>`
- **AND** SHALL be valid for the `pkgs.fetchFromGitHub` usage in the module

#### Scenario: npm dependency hash discovered
- **GIVEN** a package pin changes
- **WHEN** the script computes the `npmDepsHash`
- **THEN** it SHALL derive the hash from a real nix fetch of the package's npm dependency tree
- **AND** the resulting package SHALL build with the updated `npmDepsHash`

### Requirement: No activation or commit from update script
The `bin/update-pi` script SHALL stop after updating files and SHALL NOT deploy or version-control the change.

#### Scenario: Script leaves deployment to the user
- **GIVEN** the script has completed its file updates
- **WHEN** the script finishes
- **THEN** it SHALL NOT run `home-manager switch` or `nixos-rebuild`
- **THEN** it SHALL NOT commit or push changes
- **THEN** it SHALL print the manual next steps (apply, and commit the `Config.txt` source with the generated file)
