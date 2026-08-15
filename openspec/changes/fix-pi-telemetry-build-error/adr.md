# ADR Review Manifest

- Status: completed
- Review date: 2026-08-15

## Review Summary

ADR review completed for this change.

## In-Force ADRs Reviewed

- `adr/0001-pin-ollama-to-github-release-binaries.md` — accepted; ollama release pinning, unrelated to this change.
- `adr/0003-ollama-cloud-for-agent-configs.md` — accepted; ollama cloud provider config, unrelated to this change.
- `adr/0004-lift-pi-coding-agent-version-cap.md` — accepted (supersedes ADR-0002); the vendored provider model data mandate that this change builds upon. ADR-0002 is superseded and treated as historical only.

## New Durable ADRs Created

- `adr/0005-pi-build-follows-upstream-hermetic-order.md` — records the durable commitment that the pi module's hand-rolled `buildPhase` mirrors upstream's hermetic `build:offline` workspace ordering, including compiling `packages/telemetry` before `packages/ai`.
