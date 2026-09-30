## Why

The installed `opencode` binary is whatever nixpkgs happens to ship, because `dpom-opencode` only sets `programs.opencode.enable = true` and never pins a version. That leaves the agent three minor releases behind (installed `1.15.10` vs upstream `v1.18.33`) with no lever to pull it forward: `opencode upgrade` is unavailable under a Nix-managed install, and `nix flake update` only moves as fast as nixpkgs. `update-pi` and `update-ollama` do not have this problem because their packages are explicitly pinned in the literate Org source; `opencode` needs the same treatment.

## What Changes

- Add a pinned, prebuilt-binary `opencode` package to the `dpom-opencode` Home Manager module in `Config.txt`, and hand it to Home Manager via `programs.opencode.package` so the repo owns the version instead of nixpkgs.
- Add `bin/update-opencode`, which resolves the latest `anomalyco/opencode` release, patches the pin and its tarball hash into the Org source, re-tangles, and stops.
- **BREAKING (packaging shape, not user-facing):** the `opencode` package is no longer `pkgs.opencode`. It is a `fetchurl` of the upstream Linux release tarball. The `share/opencode/{config,tui}.json` JSON schemas that the nixpkgs recipe generates at build time are not available from a prebuilt tarball.

Two verified constraints, both discovered by building against upstream `v1.18.33`:

- The release tarball contains a single top-level `opencode` file and no directory, so nixpkgs' `unpackFile` aborts with "unpacker appears to have produced no directories". The derivation needs an explicit `unpackPhase`.
- The binary is a Bun single-file executable whose ELF interpreter is `/lib64/ld-linux-x86-64.so.2`, which does not exist inside the Nix sandbox. `autoPatchelfHook` fixes the interpreter but **corrupts the executable**: the built binary reports `1.3.14` (the embedded Bun runtime version) instead of `1.18.33`. A single explicit `patchelf --set-interpreter` preserves the binary. `autoPatchelfHook` must not be used.

## Capabilities

### New Capabilities
- `opencode-agent-update-script`: A `bin/update-opencode` script that resolves the latest `anomalyco/opencode` release and updates the pinned version and tarball hash in the literate Org source, so the opencode agent can be moved off the nixpkgs version on demand.

### Modified Capabilities
- None. No existing spec changes behavior. (`pi-agent-update-script` and `ollama-update-script` are separate scripts and are untouched.)

## Impact

- `Config.txt` — the `modules/home/opencode.nix` tangle block gains an `opencode` package definition (`version` + `fetchurl` hash) and a `programs.opencode.package` assignment. Generated `modules/home/opencode.nix` changes with it.
- `bin/update-opencode` — new script. Reads the `digest` field of the `opencode-linux-x64.tar.gz` release asset and converts it to SRI, so no hash-discovery build is needed (unlike `update-pi`'s `npmDepsHash` fake-hash round-trip).
- Build inputs: `patchelf`, `makeWrapper`, `ripgrep`, `versionCheckHook`. `ripgrep` must be on the wrapped `PATH` — opencode's grep tool needs it, same as the nixpkgs recipe.
- Applies to `hosts/mary` only, since `dpom-opencode.enable` is set only in `hosts/mary/home.nix:14`.
- No secret, API, or user-facing configuration changes. The jq-generated `~/.config/opencode/opencode.json` and its `home.activation.generateOpencode` entry are unaffected.
