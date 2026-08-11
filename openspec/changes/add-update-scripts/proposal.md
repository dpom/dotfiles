## Why

The Ollama and Pi agent applications are pinned in this NixOS config, but bumping them is a manual, error-prone chore: version, source hash, and `npmDepsHash` all have to be looked up and edited by hand. Today only oh-my-pi has an update script (`bin/update-oh-my-pi`); ollama has no pin at all (it silently tracks nixpkgs) and pi has a hardcoded pin with no update automation. Automating both keeps the AI toolchain current without guesswork.

## What Changes

- **New `bin/update-ollama`**: Fetches the latest release of `ollama/ollama` from GitHub, downloads the matching prebuilt asset (including the ROCm variant used on `mary`), computes its SRI hash, updates the version + hash fields in the ollama module *inside Config.txt*, and re-tangles to regenerate `modules/nixos/ollama.nix`.
- **Pin ollama**: `modules/nixos/ollama.nix` currently uses `pkgs.ollama.override { ... }` (unpinned, tracks nixpkgs). This change pins it to a specific GitHub release version + hash so `update-ollama` has something deterministic to bump. The NixOS service definition and GPU/ROCm options are unchanged.
- **New `bin/update-pi`**: Fetches the latest releases of both pinned pi components — `pi-coding-agent` (`earendil-works/pi`) and `pi-acp` (`svkozak/pi-acp`) — recomputes each source hash and `npmDepsHash`, updates the version/hash/`npmDepsHash` fields in the pi module *inside Config.txt*, and re-tangles to regenerate `modules/home/pi.nix`.
- **Idempotence**: Both scripts report "already up to date" and make no changes when the pinned version already matches the latest release.
- **Scope stop**: Scripts only update the repo files; they do **not** run `home-manager switch` / `nixos-rebuild` or push changes.

## Capabilities

### New Capabilities
- `ollama-update-script`: Resolves the latest ollama GitHub release and updates the pinned ollama version + hash in the NixOS ollama module source (Config.txt), regenerating `modules/nixos/ollama.nix`.
- `pi-agent-update-script`: Resolves the latest releases of `earendil-works/pi` and `svkozak/pi-acp` and updates their pinned version, source hash, and `npmDepsHash` in the home-manager pi module source (Config.txt), regenerating `modules/home/pi.nix`.

### Modified Capabilities
<!-- No existing behaviour specs change: existing specs cover agent installation and model config generation, which are untouched. -->

## Impact

- **Source of truth**: `Config.txt` — new/changed Org sections for the ollama and pi home modules (following the repo's literate-programming convention; the existing `bin/update-oh-my-pi` divergence is not addressed by this change).
- **Tangled output**: `modules/nixos/ollama.nix` (adds a version pin), `modules/home/pi.nix` (updated pins).
- **New files**: `bin/update-ollama`, `bin/update-pi`.
- **Tooling**: relies on tools already available in this repo (`curl`, `jq`, `nix hash convert`/`nix-prefetch`, `./bin/generate-admin` tangle). No new runtime dependencies.
- **Hosts**: affects both `mary` (ollama on ROCm) and `bob` (ollama on CPU); the pi module is enabled on both hosts.
