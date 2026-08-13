# ADR Review Manifest

- Status: completed
- Review date: 2026-08-11

## Review Summary

ADR review completed for this change.

## In-Force ADRs Reviewed

- None - `<repo>/adr/` has no in-force ADRs.

## New Durable ADRs Created

- `adr/0001-pin-ollama-to-github-release-binaries.md` — pins ollama to prebuilt GitHub release binaries instead of tracking nixpkgs, establishing the durable upgrade path this change implements. (Nygard style; details live in the ADR file.)
- `adr/0002-cap-pi-coding-agent.md` — caps pi-coding-agent at v0.80.3 because upstream v0.84.1+ generates provider data from live APIs at build time, breaking the hermetic Nix build; `bin/update-pi` skips newer releases with a loud note. (Nygard style; details live in the ADR file.)
