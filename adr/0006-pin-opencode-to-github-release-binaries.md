# Pin opencode to Prebuilt GitHub Release Binaries

## Status

Accepted

## Date

2026-09-30

## Context

The `dpom-opencode` Home Manager module set only `programs.opencode.enable = true`, so `programs.opencode.package` resolved to `pkgs.opencode` from the nixpkgs flake input. The installed agent therefore tracked whatever nixpkgs shipped rather than any version this repo chose, leaving no way to move it on demand: `opencode upgrade` does not apply to a Nix-managed install, and `nix flake update` advances only as fast as nixpkgs. At the time of this decision nixpkgs provided `1.15.10` while upstream `anomalyco/opencode` was at `v1.18.33`.

ADR-0001 established the pattern this applies: pin a tool to prebuilt GitHub release assets, compute an SRI hash for the asset, and drive bumps from a script that patches the literate Org source and re-tangles. That decision is scoped to the ollama NixOS service, so the equivalent commitment for opencode was not covered by it.

The nixpkgs `opencode` recipe is a source build: a `bun`/`nodejs` derivation with a nested fixed-output `node_modules` subpackage, an `env.MODELS_DEV_API_JSON` pointer at the `models-dev` package to keep model catalogs out of the build, and a `postPatch` that relaxes upstream's own Bun version check. Reproducing that inside a Home Manager module is a considerably larger commitment than the pin itself, and it would need re-verification on every bump as upstream's build scripts change.

## Decision

Pin `opencode` to an exact `anomalyco/opencode` GitHub release in the `dpom-opencode` module, using the prebuilt Linux release asset rather than a source build or `pkgs.opencode`.

- The pinned version and a source hash for the `opencode-linux-x64.tar.gz` release asset are declared in `Config.txt` and handed to Home Manager through `programs.opencode.package`, so the Org source remains the single source of truth.
- A new `bin/update-opencode` script resolves the latest release, reads the asset digest from the GitHub release API (falling back to download plus `sha256sum` when absent), patches version and hash into `Config.txt`, and re-tangles.
- The module keeps `enable = true` and its existing generated opencode configuration; only the package's origin changes.

Asset naming and tag-format drift upstream require a small script adjustment. Variant selection (for example a baseline-CPU asset) may later follow the per-variant option pattern already used for ollama's `acceleration` option.

## Consequences

- **Easier**: opencode can be moved to its exact latest upstream release on demand instead of waiting on nixpkgs, and the pin is deterministic and reviewable in git.
- **Easier**: the module no longer depends on nixpkgs' opencode recipe, which means it does not inherit nixpkgs' opencode packaging fixes either.
- **Harder**: this repo is now responsible for keeping opencode current; it no longer inherits nixpkgs' security and version updates automatically. `bin/update-opencode` is the mitigation, and nothing enforces that it gets run.
- **Harder**: the prebuilt asset does not provide `share/opencode/{config,tui}.json`, which the nixpkgs source build generates from the source tree. Runtime behavior is unaffected, since the opencode configuration is generated separately, but editor-side JSON schema validation of `opencode.json` is lost.
- **Harder**: shell completions are not obtainable from the prebuilt asset. `opencode completion` exits nonzero in the build sandbox before writing output, apparently due to the SQLite database migration that runs at opencode startup. This is a regression against the nixpkgs-provided binary and is tracked as an open question in the change that introduced this pin.
- **Follow-up**: confirm which x64 asset is correct for mary's CPU. The non-baseline asset's embedded runtime self-identifies as a baseline build, so the asset-to-CPU mapping should not be assumed.
