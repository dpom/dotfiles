# Tasks: Fix the pi-coding-agent build and keep bin/update-pi functional

## 1. Fix the pi-coding-agent build recipe

- [ ] 1.1 Add `npx tsgo -p packages/telemetry/tsconfig.build.json` to the `pi-coding-agent` `buildPhase` in the pi module block of `Config.txt`, immediately before the `packages/ai` compile step (mirroring upstream's `build:offline` order `tui → telemetry → ai → agent → …`).
- [ ] 1.2 Tangle the module with `./bin/generate-admin` (or `ent generate`) and confirm `modules/home/pi.nix` regenerates with the telemetry build step in place.

## 2. Bump pi-coding-agent to the latest release

- [ ] 2.1 Run `bin/update-pi` to resolve the latest `earendil-works/pi` release (v0.84.2) and `svkozak/pi-acp` (v0.0.33), patching the version, source hash, and `npmDepsHash` in `Config.txt`.
- [ ] 2.2 Confirm the script hydrates the provider model data snapshot into `modules/home/pi-model-data/0.84.2/` and prunes stale model-data directories.
- [ ] 2.3 Confirm the script re-tangles `modules/home/pi.nix` and leaves no `lib.fakeHash` `npmDepsHash` behind, and that `pi-acp` remains at v0.0.33.

## 3. Verify the build

- [ ] 3.1 Run `ent update-home` and confirm the `pi-coding-agent` package builds hermetically (no TS2307 on `@earendil-works/pi-telemetry`, no network access) and the home-manager switch completes.
- [ ] 3.2 Confirm the installed `pi --version` reports `0.84.2` and `pi-acp --version` reports `0.0.33`.

## 4. Close out the change

- [ ] 4.1 Run `openspec validate fix-pi-telemetry-build-error --type change --strict` and fix any validation errors.
- [ ] 4.2 Commit the `Config.txt` source, regenerated `modules/home/pi.nix`, `modules/home/pi-model-data/0.84.2/`, and any `bin/update-pi` changes together.
