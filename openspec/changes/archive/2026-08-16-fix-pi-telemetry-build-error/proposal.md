# Proposal: Fix the pi-coding-agent build and keep bin/update-pi functional

## Why

`ent update-home` fails building `pi-coding-agent v0.84.1` with `error TS2307: Cannot find module '@earendil-works/pi-telemetry'` in `packages/ai/src/types.ts:1`. The custom `buildPhase` in `modules/home/pi.nix` compiles the pi monorepo workspaces out of order and skips `packages/telemetry`, which `@earendil-works/pi-ai` now depends on. Without a buildable pin, `bin/update-pi` cannot fulfil its job of advancing the pi agent to the latest release and `home-manager switch` is broken.

## What Changes

- Fix the `pi-coding-agent` `buildPhase` in `modules/home/pi.nix` to compile `packages/telemetry` before `packages/ai`, aligning with upstream's hermetic `build:offline` ordering.
- Bump the `pi-coding-agent` pin from v0.84.1 to v0.84.2 (latest upstream): update the source `hash`, `npmDepsHash`, and re-vendor the hydrated model data snapshot into `modules/home/pi-model-data/0.84.2/`.
- Keep `pi-acp` at v0.0.33 (already latest).
- Keep `bin/update-pi` functional and idempotent so future bumps work: hydration of model data, `npmDepsHash` discovery, and tangle must all succeed.
- All module changes stay in the literate Org source (`Config.txt`) and are re-tangled via `./bin/generate-admin`.

## Capabilities

### New Capabilities
- None. The build fix and version bump extend existing behaviour.

### Modified Capabilities
- `pi-coding-agent`: the hermetic build must compile the `telemetry` workspace package before `ai`, and the pinned version moves to v0.84.2 with matching source hash, `npmDepsHash`, and vendored model data. The module's `dpom-pi.enable` toggle, PATH availability, provider presets, and activation behaviour are unchanged.
- `pi-agent-update-script`: `bin/update-pi` must produce a buildable pin at the latest `earendil-works/pi` release (hydrate model data, discover `npmDepsHash`, tangle) and remain idempotent, verified by `ent update-home`.

## Impact

- `modules/home/pi.nix` (tangled from `Config.txt`) — `buildPhase` order, version/hash/`npmDepsHash` pins.
- `modules/home/pi-model-data/` — new vendored snapshot for v0.84.2, stale dirs pruned.
- `bin/update-pi` — verified to bump and build; no code change expected unless verification reveals a defect.
- `home-manager` activation — package build now succeeds; runtime behaviour and activation hooks unchanged.
- Hosts mary and bob (both enable `dpom-pi`) get the rebuilt `pi` binary after `ent update-home`.
