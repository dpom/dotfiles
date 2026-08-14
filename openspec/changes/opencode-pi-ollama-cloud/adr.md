# ADR Review Manifest

- Status: completed
- Review date: 2026-08-14

## Review Summary

ADR review completed for this change.

## In-Force ADRs Reviewed

- `adr/0001-pin-ollama-to-github-release-binaries.md` — pins the local ollama daemon to GitHub release binaries; coherent with this change since cloud access is a direct endpoint independent of the local daemon.
- `adr/0002-cap-pi-coding-agent.md` — capped pi-coding-agent at v0.80.3; superseded in practice by the vendored `pi-model-data` recipe and recorded as superseded by ADR-0004 (below).

## New Durable ADRs Created

- `adr/0003-ollama-cloud-for-agent-configs.md` — durable decision to add Ollama Cloud as a hosted, OpenAI-compatible provider for the opencode and pi config templates, with a statically pinned free-tier catalog and SOPS-managed API key.
- `adr/0004-lift-pi-coding-agent-version-cap.md` — supersedes ADR-0002; the pi module recipe vendors provider model data (`modules/home/pi-model-data/<version>`), lifting the v0.80.3 cap as the ADR's own condition intended.
