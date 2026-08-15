# Mirror Upstream Hermetic Build Order for pi-coding-agent

## Status

Accepted

## Date

2026-08-15

## Context

`pi-coding-agent` is built in `modules/home/pi.nix` with a hand-rolled `buildPhase` that compiles selected pi monorepo workspaces individually via `npx tsgo -p packages/<ws>/tsconfig.build.json`. Upstream `@earendil-works/pi` v0.84.x introduced a new workspace dependency: `@earendil-works/pi-ai` depends on `@earendil-works/pi-telemetry`, whose type declarations only exist in `dist/` after the telemetry workspace is compiled. The hand-rolled phase compiled `ai` without first compiling `telemetry`, breaking the build with `TS2307: Cannot find module '@earendil-works/pi-telemetry'`.

Upstream's hermetic build path (`npm run build:offline`) compiles the workspaces in a strict order: `tui → telemetry → ai → agent → … → coding-agent`. The Nix recipe already follows this ordering for the workspaces it compiles; the gap was a missing workspace, not a wrong order.

## Decision

Keep the hand-rolled `buildPhase` in the pi module, but mandate that its workspace list and order mirror upstream's hermetic `build:offline` sequence for every workspace the phase compiles. When a workspace in that sequence is added to (or removed from) upstream, the recipe SHALL be updated to match before the pinned version is raised. In particular, `packages/telemetry` SHALL be compiled before `packages/ai`.

## Consequences

- **Easier**: future pi bumps are less likely to fail with "cannot find module" errors for newly added workspace dependencies, because the ordering contract is explicit.
- **Easier**: `bin/update-pi`'s acceptance check (`ent update-home`) now exercises the ordering contract on every bump.
- **Harder**: every version bump should re-verify the workspace list against upstream's `build:offline`; a mismatch surfaces only as a build failure unless checked.
- **Follow-up**: none — this records the ordering mandate ADR-0004's vendored-data recipe already implies.
