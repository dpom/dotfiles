## ADDED Requirements

### Requirement: Opencode latest release resolution
The `bin/update-opencode` script SHALL resolve the latest stable release of `anomalyco/opencode` from GitHub.

Feature: opencode-agent-update-script
Rule: Resolving the upstream release to move the pin toward

#### Scenario: Latest release resolved and reported
- **GIVEN** the opencode module pins a version older than the latest release
- **WHEN** the script is run
- **THEN** the latest release tag SHALL be resolved from GitHub
- **AND** the resolved version SHALL be reported to the user
- **AND** the currently pinned version SHALL be reported alongside it

#### Scenario: Already at the latest version
- **GIVEN** the opencode module already pins the latest release version
- **WHEN** the script is run
- **THEN** the script SHALL report that opencode is already up to date
- **AND** SHALL NOT modify any file

#### Scenario: Unexpected release tag format
- **GIVEN** the resolved release tag does not match the expected `vX.Y.Z` form
- **WHEN** the script parses the tag
- **THEN** the script SHALL stop without modifying any file
- **AND** SHALL report the tag it received and the form it expected

#### Scenario: Release metadata is unreachable
- **GIVEN** the GitHub release API request does not succeed
- **WHEN** the script is run
- **THEN** the script SHALL stop without modifying any file
- **AND** SHALL report the failure

### Requirement: Pinned opencode package in the literate Org source
The `dpom-opencode` module SHALL define an `opencode` package pinned to an exact release version and a source hash for that release's Linux prebuilt asset, and Home Manager SHALL install that pinned package rather than the nixpkgs `opencode`.

Feature: opencode-agent-update-script
Rule: The repo owns the opencode version instead of nixpkgs

#### Scenario: Home Manager installs the pinned package
- **GIVEN** a host with `dpom-opencode.enable = true`
- **WHEN** the Home Manager configuration is applied
- **THEN** the installed `opencode` command SHALL come from the module's pinned package
- **AND** SHALL NOT come from the nixpkgs `opencode` package

#### Scenario: Version and hash pinned together
- **GIVEN** the opencode module
- **WHEN** inspected
- **THEN** the module SHALL declare the pinned opencode version
- **AND** the module SHALL declare a source hash for that version's release asset

#### Scenario: Version and hash correspond to the same release
- **GIVEN** the module declares a pinned version and a source hash
- **WHEN** the pinned package is built
- **THEN** the source hash SHALL be the hash of the release asset published for that version
- **AND** the build SHALL succeed without a hash mismatch error

#### Scenario: Existing module behaviour preserved
- **GIVEN** the opencode module with a pinned package
- **WHEN** the Home Manager configuration is applied
- **THEN** the module's `enable` option SHALL continue to control activation
- **AND** the generated opencode configuration SHALL still be produced by the module's existing config generation
- **AND** the module's providers and model definitions SHALL be unchanged

### Requirement: Pinned package runs in the Nix sandbox
The pinned `opencode` package SHALL build in a hermetic Nix sandbox and produce a working command.

Feature: opencode-agent-update-script
Rule: The prebuilt asset is made runnable under Nix

This is required because the release asset is a single bare executable file rather than a directory-based source tree, and because its ELF interpreter refers to a host path that does not exist inside the sandbox.

#### Scenario: Release asset unpacks
- **GIVEN** the release asset contains a single top-level `opencode` file and no directory
- **WHEN** the pinned package is built
- **THEN** the package SHALL extract the asset successfully
- **AND** the build SHALL NOT fail because the unpacker produced no directories

#### Scenario: Command is executable in the sandbox
- **GIVEN** the release binary's ELF interpreter refers to a host path
- **WHEN** the pinned package is built
- **THEN** the installed command SHALL have its ELF interpreter repointed at a store path
- **AND** the command SHALL execute inside the build sandbox

#### Scenario: Automatic dependency rewriting is not used
- **GIVEN** the release binary is a single-file executable
- **WHEN** the pinned package is built
- **THEN** the build SHALL NOT apply automatic ELF dependency rewriting to the binary
- **AND** SHALL repoint the interpreter explicitly instead

The final scenario encodes a verified failure: automatic dependency rewriting silently corrupts this binary, leaving it reporting its embedded runtime version instead of the opencode version. Because the corruption is silent, it is specified as a prohibition rather than left to implementation judgement.

#### Scenario: Grep tooling is available to the agent
- **GIVEN** the opencode agent's grep tool shells out to `rg`
- **WHEN** the pinned package is installed
- **THEN** `rg` SHALL be available on the command's `PATH`

### Requirement: Built package reports the pinned version
The pinned `opencode` package SHALL verify at build time that the command reports the version that was pinned, and the build SHALL fail if it does not.

Feature: opencode-agent-update-script
Rule: A silently broken build must not be installable

#### Scenario: Binary reports the pinned version
- **GIVEN** the pinned package has been built
- **WHEN** the install-time version check runs
- **THEN** the check SHALL pass
- **AND** the package SHALL be installable

#### Scenario: Binary reports a different version
- **GIVEN** the built binary reports a version other than the pinned one
- **WHEN** the install-time version check runs
- **THEN** the build SHALL fail
- **AND** the failure SHALL be reported to the user
- **AND** the package SHALL NOT be installable

### Requirement: Release asset hash resolution
The `bin/update-opencode` script SHALL determine the source hash for the release asset without requiring the user to compute it by hand.

Feature: opencode-agent-update-script
Rule: Obtaining the hash of the new release asset

#### Scenario: Hash read from the release API
- **GIVEN** the release API reports a digest for the opencode release asset
- **WHEN** the script resolves the hash for the new version
- **THEN** the script SHALL derive the source hash from the reported digest
- **AND** SHALL NOT require downloading the asset to compute it

#### Scenario: Digest absent, hash computed by download
- **GIVEN** the release API reports no digest for the release asset
- **WHEN** the script resolves the hash for the new version
- **THEN** the script SHALL download the release asset and compute its hash
- **AND** SHALL record the computed hash as the pinned source hash

#### Scenario: Expected asset is absent from the release
- **GIVEN** the release does not publish the expected opencode asset
- **WHEN** the script resolves the release contents
- **THEN** the script SHALL stop without modifying any file
- **AND** SHALL report the expected asset name

### Requirement: Pin update in the Org source
Running `bin/update-opencode` SHALL update the pinned version and source hash in the opencode module definition inside `Config.txt`, then re-tangle so the generated `modules/home/opencode.nix` is regenerated.

Feature: opencode-agent-update-script
Rule: Editing the source of truth and regenerating from it

#### Scenario: Pin updated in the Org source
- **GIVEN** a newer opencode release exists than the pinned version
- **WHEN** the script updates the pin
- **THEN** the pinned version in `Config.txt` SHALL match the resolved release
- **AND** the pinned source hash SHALL match that release's asset
- **AND** the generated `modules/home/opencode.nix` SHALL reflect the updated values

#### Scenario: Generated module is consistent with the Org source
- **GIVEN** the script has updated the opencode module block in `Config.txt`
- **WHEN** the script finishes its edits
- **THEN** the re-tangle step SHALL run
- **AND** the regenerated `modules/home/opencode.nix` SHALL be consistent with the updated `Config.txt`

#### Scenario: Update is verified after writing
- **GIVEN** the script has written its changes
- **WHEN** the script verifies the result
- **THEN** the script SHALL confirm the intended version and hash are present in the Org source
- **AND** SHALL stop with a clear error if the write did not take effect

#### Scenario: Generated files are not edited directly
- **GIVEN** the script has updated the pin
- **WHEN** it writes files
- **THEN** it SHALL edit the literate Org source
- **AND** SHALL regenerate the Nix module by tangling
- **AND** SHALL NOT hand-edit the generated `modules/home/opencode.nix`

### Requirement: Updated pin builds and reports the new version
After `bin/update-opencode` raises the pin, the regenerated module SHALL build and yield a command reporting the newly pinned version.

Feature: opencode-agent-update-script
Rule: A new pin is usable, not merely written

#### Scenario: Bumped pin builds and runs
- **GIVEN** `bin/update-opencode` has raised the pin to a newer opencode release
- **WHEN** the Home Manager configuration is applied
- **THEN** the pinned package SHALL build without manual hash or recipe edits
- **AND** the installed command SHALL report the newly pinned version

#### Scenario: New pin moves the agent off the nixpkgs version
- **GIVEN** the pinned version is newer than the version nixpkgs provides
- **WHEN** the pin is applied
- **THEN** the installed opencode version SHALL be the pinned version
- **AND** SHALL no longer be limited by the version nixpkgs happens to ship
