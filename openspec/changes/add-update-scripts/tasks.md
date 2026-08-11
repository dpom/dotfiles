## 1. Pin Ollama in the NixOS module (Config.txt)

- [ ] 1.1 Restructure the ollama module block in `Config.txt` to add versioned prebuilt binary derivations for the CPU (`ollama-linux-amd64`) and ROCm (`ollama-linux-amd64-rocm`) variants, each with a pinned version and SRI hash, wired to `services.ollama.package` via the existing `dpom-ollama.acceleration` option
- [ ] 1.2 Verify `services.ollama` options, `environmentVariables`, and ROCm packages in the module remain unchanged
- [ ] 1.3 Run `./bin/generate-admin` and confirm `modules/nixos/ollama.nix` is regenerated consistently from `Config.txt`
- [ ] 1.4 Sanity-build the ollama service for both hosts (`nix build .#nixosConfigurations.mary.config.system.build.toplevel` and bob) to confirm both variants evaluate

## 2. Implement bin/update-ollama

- [ ] 2.1 Write `bin/update-ollama` (bash, `set -euo pipefail`) that resolves the latest `ollama/ollama` release tag from the GitHub API
- [ ] 2.2 Download both `ollama-linux-amd64` and `ollama-linux-amd64-rocm` assets, compute SRI hashes, and convert to SRI form
- [ ] 2.3 Patch the ollama module block in `Config.txt` (block-scoped, multi-line `sed` anchors) with the new version + both hashes, then re-tangle via `./bin/generate-admin`
- [ ] 2.4 Implement idempotence: if the pinned version already matches the latest release, report "already up to date" and exit without modifying files
- [ ] 2.5 Verify the script does not run `nixos-rebuild`/`home-manager switch` or git operations, and prints manual next steps
- [ ] 2.6 Test the ROCm variant runs under the `services.ollama` service on mary (start service, `ollama list` works); if the prebuilt ROCm binary is broken, fall back to the `overrideAttrs` source build per design Decision 1 and note it in the script header

## 3. Implement bin/update-pi

- [ ] 3.1 Write `bin/update-pi` (bash, `set -euo pipefail`) that independently resolves the latest release tags of `earendil-works/pi` and `svkozak/pi-acp`
- [ ] 3.2 Compute each package's source hash with `nix-prefetch-url --unpack` on the `archive/refs/tags/v<version>.tar.gz` URL, converted to SRI
- [ ] 3.3 Implement `npmDepsHash` discovery: set `lib.fakeHash`, run the package build, parse the real hash from the `got:` error line, and write it back
- [ ] 3.4 Patch the pi module block in `Config.txt` (block-scoped anchors for `pi-coding-agent` and `pi-acp`) with new version/hash/`npmDepsHash`, then re-tangle via `./bin/generate-admin`
- [ ] 3.5 Implement idempotence: skip when both pinned versions already match latest; verify the hash round-trip against a current pin without bumping
- [ ] 3.6 Verify the script does not run `home-manager switch`/`nixos-rebuild` or git operations, and prints manual next steps

## 4. Validate and land

- [ ] 4.1 Run `openspec validate add-update-scripts --type change --strict` and fix any failures
- [ ] 4.2 Review `git diff` of `Config.txt` + regenerated `modules/nixos/ollama.nix` / `modules/home/pi.nix`; commit source and generated files together
- [ ] 4.3 Run the scripts against the current pins to confirm the idempotent "already up to date" path end-to-end
