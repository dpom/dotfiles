# ollama-update-script

## Purpose

Provide a `bin/update-ollama` script that resolves the latest ollama release from GitHub and updates the pinned ollama version and variant hashes in the literate Org source, regenerating the module without deploying or committing.

## Requirements

### Requirement: Ollama latest release resolution
The `bin/update-ollama` script SHALL resolve the latest stable release of `ollama/ollama` from GitHub.

#### Scenario: Latest release found
- **GIVEN** the script is run
- **WHEN** it queries GitHub for the latest `ollama/ollama` release
- **THEN** the release tag SHALL be resolved successfully
- **AND** the version SHALL be reported to the user

#### Scenario: Already at the latest version
- **GIVEN** the ollama module already pins the latest release version
- **WHEN** the script is run
- **THEN** the script SHALL report that ollama is already up to date
- **AND** SHALL NOT modify any files

### Requirement: Pinned ollama module with per-variant hashes
The `modules/nixos/ollama.nix` module SHALL pin ollama to an exact GitHub release version, with a separate pinned source hash for the CPU (`ollama-linux-amd64`) and ROCm (`ollama-linux-amd64-rocm`) prebuilt variants.

#### Scenario: Variant selected by acceleration option
- **GIVEN** `dpom-ollama.acceleration = "rocm"` on a host (e.g. mary)
- **WHEN** the ollama package is evaluated
- **THEN** the ROCm variant SHALL be selected for the `services.ollama` package
- **GIVEN** `dpom-ollama.acceleration` is unset/null on a host (e.g. bob)
- **WHEN** the ollama package is evaluated
- **THEN** the CPU variant SHALL be selected for the `services.ollama` package

#### Scenario: Version and hashes pinned
- **GIVEN** the ollama module
- **WHEN** inspected
- **THEN** the module SHALL declare the pinned ollama version
- **THEN** the module SHALL declare the CPU variant source hash
- **THEN** the module SHALL declare the ROCm variant source hash

### Requirement: Ollama version and hash update in Org source
Running `bin/update-ollama` SHALL update the pinned ollama version and both variant hashes in the ollama module definition inside `Config.txt`, then re-tangle so `modules/nixos/ollama.nix` is regenerated.

#### Scenario: Files updated and regenerated
- **GIVEN** a newer ollama release exists
- **WHEN** the script updates the pin
- **THEN** the ollama module block in `Config.txt` SHALL reflect the new version and variant hashes
- **THEN** `./bin/generate-admin` SHALL re-tangle `modules/nixos/ollama.nix`
- **THEN** the regenerated `modules/nixos/ollama.nix` SHALL be consistent with the updated `Config.txt`

#### Scenario: Existing service options preserved
- **GIVEN** the ollama module
- **WHEN** the update script changes the pinned version
- **THEN** the `dpom-ollama` service options (enable, acceleration, loadModels, environmentVariables) SHALL remain unchanged

### Requirement: No activation or commit from update script
The `bin/update-ollama` script SHALL stop after updating files and SHALL NOT deploy or version-control the change.

#### Scenario: Script leaves deployment to the user
- **GIVEN** the script has completed its file updates
- **WHEN** the script finishes
- **THEN** it SHALL NOT run `nixos-rebuild` or `home-manager switch`
- **THEN** it SHALL NOT commit or push changes
- **THEN** it SHALL print the manual next steps (apply, and commit the `Config.txt` source with the generated file)
