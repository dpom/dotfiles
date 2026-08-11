# Pin Ollama to Prebuilt GitHub Release Binaries

## Status

Accepted

## Context

The ollama NixOS service (`modules/nixos/ollama.nix`) is installed from `pkgs.ollama` in the nixpkgs flake input, with no version pinned in this repo. This means ollama silently tracks whatever version nixpkgs ships on `nixos-26.05`, which lags upstream releases, and there is no deterministic way to bump it on demand. The existing update automation (`bin/update-oh-my-pi`) establishes a proven pattern: fetch the latest GitHub release asset, compute its SRI hash, and pin it in the module. The user wants ollama to track its latest upstream release, like oh-my-pi does.

## Decision

Pin ollama to an exact `ollama/ollama` GitHub release in the NixOS ollama module, using the prebuilt release binaries (oh-my-pi pattern):

- CPU hosts (`dpom-ollama.acceleration` unset, e.g. bob): `ollama-linux-amd64`.
- ROCm hosts (`dpom-ollama.acceleration = "rocm"`, e.g. mary): `ollama-linux-amd64-rocm`.

Both variant hashes are pinned alongside the version; the existing `acceleration` option selects the variant. A new `bin/update-ollama` script resolves the latest release, downloads both assets, and updates version + both hashes in `Config.txt`, then re-tangles. This deliberately abandons "track nixpkgs" as the ollama upgrade path.

## Consequences

- **Easier**: ollama can be brought to its exact latest upstream release on demand without waiting for nixpkgs; hash computation is a simple download + `sha256sum`.
- **Easier**: the pin is deterministic and reviewable in git.
- **Harder**: the repo is now responsible for keeping ollama current; it no longer inherits nixpkgs security/version updates automatically.
- **Harder**: the prebuilt ROCm binary must run correctly with the module's existing ROCm packages on mary; if not, fall back to an `overrideAttrs` source build of `pkgs.ollama`.
- **Follow-up**: asset naming or tag-format drift upstream requires a small script adjustment; `bin/update-oh-my-pi`'s divergence from the Config.txt source-of-truth convention is noted but not addressed here.
