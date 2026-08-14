# Lift the pi-coding-agent Version Cap via Vendored Provider Model Data

## Status

accepted, supersedes ADR-0002

## Date

2026-08-14

Supersedes: ADR-0002

## Context

ADR-0002 capped `pi-coding-agent` at v0.80.3 because upstream builds from v0.84.1 fetch live provider catalogs (`packages/ai` runs `npm run generate-models`), which fails a hermetic Nix build. ADR-0002 named the lifting condition: vendor the generated provider data into the repo and apply it as a build patch.

The pi module recipe has since implemented exactly that: `modules/home/pi.nix` vendors `./pi-model-data/<version>` and applies it via `postPatch`, and the pin now sits at v0.84.1. `bin/update-pi` hydrates a fresh model-data snapshot into `modules/home/pi-model-data/<version>/` on each bump and carries an empty max-buildable cap for `pi-coding-agent`. The v0.80.3 cap no longer matches the implementation, but no superseding ADR was recorded.

## Decision

Record that the v0.80.3 cap in ADR-0002 is lifted. pi-coding-agent version tracking continues via the vendored `pi-model-data` recipe: every pin move must vendor the matching generated provider data before the pin is raised, preserving hermetic builds. `bin/update-pi` enforces this by hydrating and pruning the data directories as part of the update.

## Consequences

- **Easier**: the repo can track newer pi releases that ship with the generated-data build, rather than being frozen at v0.80.3.
- **Easier**: the build stays hermetic because the provider data is vendored into the repo instead of fetched at build time.
- **Harder**: every pi version bump requires vendoring and verifying the matching provider model data (`bin/update-pi` automates the hydration).
- **Follow-up**: none — the vendored-data recipe described as the lifting condition is in place and enforced by `bin/update-pi`.
