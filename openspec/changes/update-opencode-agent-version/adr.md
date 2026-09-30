# ADR Review Manifest

- Status: completed
- Review date: 2026-09-30

## Review Summary

ADR review completed for this change.

Every ADR in `<repo>/adr/` was read and the supersession graph built from each `Supersedes:` field. Two decisions in this change's design met the bar for a durable architectural decision and are recorded as new repository-level ADRs. Neither supersedes an existing ADR; both are additive.

The remaining design decisions were reviewed and deliberately **not** recorded, because they are implementation detail rather than architectural commitment: injecting the pin via `programs.opencode.package` rather than `home.packages` (D2), the explicit `unpackPhase` (D3, folded into ADR-0007 as the asset-layout half of the same problem), `makeWrapper` with `ripgrep` (D5, folded into ADR-0007), and the script's idempotent no-deploy behavior plus the absence of an `ent` task (D8). The babashka choice and API-digest hashing in D7 follow ADR-0001's in-force mechanism and introduce no new commitment.

## In-Force ADRs Reviewed

The in-force set, derived by walking `Supersedes` links:

- `adr/0001-pin-ollama-to-github-release-binaries.md` — accepted, in force. Direct precedent: the prebuilt-release-asset pattern, API-digest hashing, and the accepted "repo owns currency" trade-off. This change applies that pattern to opencode rather than diverging from it, so no supersession.
- `adr/0002-cap-pi-coding-agent.md` — **superseded by ADR-0004**, therefore historical context only and not treated as a live commitment. Its rejection of non-hermetic upstream data generation is the failure mode ADR-0006 avoids by not building opencode from source at all.
- `adr/0003-ollama-cloud-for-agent-configs.md` — accepted, in force. Touches the same generated opencode configuration that this change leaves untouched, so it constrains the change only to the effect that the config generation must not be disturbed.
- `adr/0004-lift-pi-coding-agent-version-cap.md` — accepted, in force, supersedes ADR-0002. Establishes vendored-data plus script automation as the accepted remedy for packages that cannot be built hermetically. Relevant because it shows the repo's preference for a script-driven pin over a hand-maintained cap.
- `adr/0005-pi-build-follows-upstream-hermetic-order.md` — accepted, in force. Not applicable to a prebuilt asset, but confirms the repo's general expectation that packaging constraints be verified against upstream on every bump.

No in-force ADR is contradicted by this change, and none requires supersession.

## New Durable ADRs Created

- `adr/0006-pin-opencode-to-github-release-binaries.md` — records that the opencode agent is pinned to a prebuilt upstream release asset and that the repo, not nixpkgs, owns its currency, together with the accepted losses (JSON schemas, shell completions).
- `adr/0007-no-auto-patching-of-prebuilt-agent-binaries.md` — records the prohibition on automatic ELF dependency rewriting for Bun-style prebuilt binaries, and mandates the build-time version assertion that enforces it. Scoped explicitly to this binary class so it is not misread as a general ban on `autoPatchelfHook`.
