# Design: Fix the pi-coding-agent build and keep bin/update-pi functional

## Context

`ent update-home` builds `pi-coding-agent` via a custom `buildPhase` in `modules/home/pi.nix` (tangled from `Config.txt`). The phase compiles selected pi monorepo workspaces by hand with `npx tsgo -p packages/<ws>/tsconfig.build.json`, then builds the `coding-agent` workspace. Upstream `@earendil-works/pi-ai` v0.84.x gained a dependency on the `@earendil-works/pi-telemetry` workspace package, but the custom phase never compiles `packages/telemetry`, so `npx tsgo -p packages/ai/tsconfig.build.json` fails with `TS2307: Cannot find module '@earendil-works/pi-telemetry'`.

The repo's `bin/update-pi` (babashka) resolves latest GitHub releases for `pi-coding-agent` (`earendil-works/pi`) and `pi-acp`, patches version/source-hash/`npmDepsHash` in `Config.txt`, re-tangles via `./bin/generate-admin`, hydrates vendored provider model data into `modules/home/pi-model-data/<version>/`, discovers `npmDepsHash` via a fake-hash build, and stops without deploying. It is currently non-functional because the pinned v0.84.1 cannot build.

In-force ADRs constraining this design: ADR-0004 (lift the v0.80.3 cap via vendored provider model data — every pin move must vendor the matching generated data before the pin is raised). ADR-0002 is superseded by ADR-0004 and is historical only.

## Goals / Non-Goals

**Goals:**
- Make the `pi-coding-agent` Nix build hermetic and succeed at the latest upstream version.
- Bump the pin to v0.84.2 (latest upstream as of 2026-08-14) with matching source hash, `npmDepsHash`, and vendored model data.
- Keep `bin/update-pi` functional and idempotent for future bumps, verified by `ent update-home`.
- All module changes flow through the literate Org source (`Config.txt`) and tangle.

**Non-Goals:**
- No runtime behaviour change: provider presets, activation hooks, and the `dpom-pi.enable` toggle stay as-is.
- No change to `pi-acp` (already at latest v0.0.33).
- No NixOS system rebuild or commit/push by the script — that stays a manual user step.

## Decisions

### D1: Compile `packages/telemetry` before `packages/ai` in the buildPhase

Add `npx tsgo -p packages/telemetry/tsconfig.build.json` to the `buildPhase`, immediately before the `ai` build. This mirrors upstream's hermetic `build:offline` ordering, which runs `tui → telemetry → ai → agent → … → coding-agent`.

Rationale: `@earendil-works/pi-ai` resolves `@earendil-works/pi-telemetry` via the workspace symlink to `packages/telemetry`, whose `package.json` points `types` at `./dist/index.d.ts`. `dist` only exists after that workspace is compiled, so telemetry must be built first. The telemetry package has no build-time deps on other workspaces, so it can be slotted in before `ai` with no further ordering work.

Alternatives considered:
- Run upstream's root `npm run build:offline` verbatim instead of hand-rolled `tsgo` steps. Rejected: the repo vendors model data and builds via `postPatch` + a specific offline path; delegating to the root script would lose the vendored-data injection and the pinned toolchain the current phase establishes.
- Downgrade to v0.80.3. Rejected: ADR-0004 already lifted that cap; the repo intends to track latest.

### D2: Bump pi-coding-agent to v0.84.2

Update `version`, source `hash`, and `npmDepsHash` for `pi-coding-agent` in the pi module block, and vendor `modules/home/pi-model-data/0.84.2/` from the v0.84.2 source, pruning stale `pi-model-data` dirs. `bin/update-pi` already performs these steps; the proposal's scope is to make that path actually build.

Rationale: v0.84.2 is the latest upstream release (2026-08-14), and the user wants the newest tag. Keeping the source-build recipe (no prebuilt binaries) preserves the hermetic, sandboxed build ADR-0004 mandates.

### D3: `bin/update-pi` unchanged unless verification fails

The script's existing flow (resolve → patch → tangle → hydrate → discover `npmDepsHash` → verify) is complete. The defect is the missing telemetry build step in `modules/home/pi.nix`, not the script. So the primary fix is in the Nix recipe; `bin/update-pi` is exercised as the mechanism to apply the bump and as the acceptance vehicle (`ent update-home`).

Rationale: keep the change minimal; only patch the script if `ent update-home` after the recipe fix exposes a script defect (e.g. `npmDepsHash` discovery or hydration fails against v0.84.2).

## Risks / Trade-offs

- [Upstream `pi` changes workspace build order in a future release] -> The buildPhase is now aligned with upstream's `build:offline` order for the compiled set; future bumps should re-verify the order, ideally via `ent update-home` as part of the update script's manual next-steps.
- [Hydration for v0.84.2 produces a different data set than v0.84.1] -> `bin/update-pi` validates hydration output (`.manifest.json` present, non-empty data files) and dies loudly; the vendored dir is pruned only after successful hydration.
- [The hand-rolled tsgo phase diverges further from upstream's scripts] -> Mitigated by keeping the step list faithful to upstream's offline build order and by only compiling the workspaces the recipe needs.

## Migration Plan

1. Edit the pi module block in `Config.txt` (buildPhase order + v0.84.2 pins as produced by `bin/update-pi`).
2. Run `./bin/generate-admin` to tangle `modules/home/pi.nix`.
3. Run `bin/update-pi` to resolve latest, patch pins, hydrate `pi-model-data/0.84.2/`, discover `npmDepsHash`, and re-tangle.
4. Run `ent update-home` as the acceptance check.
5. Rollback: revert the `Config.txt` block and the `pi-model-data` dir via git; the previous v0.84.1 pin remains the fallback.

## Open Questions

- Does v0.84.2 introduce any additional workspace dependency ordering beyond `telemetry`? Resolved during `ent update-home`; if the build fails on a later workspace, add the missing `tsgo` step.
- Whether `bin/update-pi` needs a code change for v0.84.2 (e.g. changed hydration script arguments). Resolved by running it; if it defects, that fix is part of this change's tasks.
- No in-force ADR needs revisiting; ADR-0004's vendored-data mandate is honoured by the v0.84.2 snapshot.
