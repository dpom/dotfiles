## 1. Pin Ollama in the NixOS module (Config.txt)

- [x] 1.1 Restructure the ollama module block in `Config.txt` to add versioned prebuilt binary derivations for the CPU (`ollama-linux-amd64`) and ROCm (`ollama-linux-amd64-rocm`) variants, each with a pinned version and SRI hash, wired to `services.ollama.package` via the existing `dpom-ollama.acceleration` option. The ROCm asset turned out to be libs-only (`lib/ollama/rocm_v7_2/`), so the rocm variant layers it over the base binary (`ollama-rocm-libs` derivation + `overrideAttrs`).
- [x] 1.2 Verify `services.ollama` options, `environmentVariables`, and ROCm packages in the module remain unchanged
- [x] 1.3 Tangle `Config.txt` and confirm `modules/nixos/ollama.nix` is regenerated consistently. Fixed a stale `bin/generate-admin`: `bin/tangle-admin.el` only globbed `.org` while the sources are `.txt`, so it tangles nothing.
- [x] 1.4 Build the ollama service package for both hosts (mary rocm + bob cpu) and confirm both variants evaluate; both binaries run (`ollama --version` reports the pinned client version)

## 2. Implement bin/update-ollama

- [x] 2.1 Write `bin/update-ollama` (bash, `set -euo pipefail`) that resolves the latest `ollama/ollama` release tag from the GitHub API
- [x] 2.2 Compute SRI hashes for both `ollama-linux-amd64` and `ollama-linux-amd64-rocm` assets. Uses the GitHub API asset `digest` (verified equal to the downloaded files' sha256) with a curl+`sha256sum` fallback, avoiding ~2.4 GB re-downloads per bump.
- [x] 2.3 Patch the ollama module block in `Config.txt` (block-scoped sed anchors via `\|...|` delimiters) with the new version + both hashes, then re-tangle via `./bin/generate-admin`
- [x] 2.4 Implement idempotence: if the pinned version already matches the latest release, report "already up to date" and exit without modifying files
- [x] 2.5 Verify the script does not run `nixos-rebuild`/`home-manager switch` or git operations, and prints manual next steps
- [x] 2.6 Test the ROCm variant runs on mary: `ollama serve` on a test port loads `rocm_v7_2` libs, detects the AMD GPU (`compute=gfx1150`), and `/api/tags` serves the model store. Prebuilt ROCm binary works — no source-build fallback needed.

## 3. Implement bin/update-pi

- [x] 3.1 Write `bin/update-pi` (bash, `set -euo pipefail`) that independently resolves the latest release tags of `earendil-works/pi` and `svkozak/pi-acp`
- [x] 3.2 Compute each package's source hash with `nix-prefetch-url --unpack` on the `archive/refs/tags/v<version>.tar.gz` URL, converted to SRI
- [x] 3.3 Implement `npmDepsHash` discovery: set `lib.fakeHash`, run the package build, parse the real hash from the `got:` error line, and write it back
- [x] 3.4 Patch the pi module block in `Config.txt` (anchors on `pname`/`owner`/`hash`) with new version/hash/`npmDepsHash`, then re-tangle via `./bin/generate-admin`. `pi-acp` bumped v0.0.31→v0.0.33. `pi-coding-agent` is capped at v0.80.3 (see ADR 0002): v0.84.1+ generates `providers/data` from live APIs at build time, breaking the hermetic Nix build; the script skips newer releases with a loud message.
- [x] 3.5 Implement idempotence: skip when both pinned versions already match latest; verified the hash round-trip against the current pins without bumping (`nix-prefetch-url --unpack` output converts exactly to the pinned SRI; discovered `npmDepsHash` values were written back and `pi-acp` builds successfully with them)
- [x] 3.6 Verify the script does not run `home-manager switch`/`nixos-rebuild` or git operations, and prints manual next steps

## 4. Validate and land

- [x] 4.1 Run `openspec validate add-update-scripts --type change --strict` and fix any failures
- [x] 4.2 Review `git diff` of `Config.txt` + regenerated `modules/nixos/ollama.nix` / `modules/home/pi.nix`; commit source and generated files together
- [x] 4.3 Run the scripts against the current pins to confirm the idempotent "already up to date" path end-to-end (both confirmed: `bin/update-ollama` at v0.32.9, `bin/update-pi` with pi-acp v0.0.33 + pi-coding-agent capped — both exit 0 with no changes)
