# Add Ollama Cloud as a Hosted Provider for Agent Configs

## Status

Accepted

## Date

2026-08-14

## Context

Both agent configs are generated at Home Manager activation time and expose only local providers (ollama at `localhost:11434`, lmstudio at `localhost:1234`), capping agent quality at whatever the host GPU can run. Ollama Cloud offers hosted open models on a free tier (no subscription) reachable through an OpenAI-compatible API at `https://ollama.com/v1`, authenticated with an API key. The local ollama daemon (pinned per ADR-0001) is not involved in cloud access.

Considered options:

- **Local ollama proxy**: list `:cloud` models against `localhost:11434`. Works only when the local daemon is running and signed in, and uses different model names (`gpt-oss:20b-cloud` vs the direct API's `gpt-oss:20b`).
- **Native cloud API**: `https://ollama.com/api` — not OpenAI-compatible, requires a different client wiring.
- **Direct OpenAI-compatible endpoint**: `https://ollama.com/v1` — chosen, since both tools already speak OpenAI-compatible for their local providers.

## Decision

Add a third `ollama-cloud` provider to the opencode and pi config templates pointing at `https://ollama.com/v1`, leaving the local `ollama` and `lmstudio` providers untouched. The free-tier model catalog is pinned statically in the templates (deterministic and reviewable, matching the ADR-0001 pinning ethos). The API key is managed as a SOPS secret (`ollama_cloud_api_key`) and injected into the generated configs at activation time. opencode's default model points at the cloud provider (`ollama-cloud/gpt-oss:20b`); pi's default provider/model is unchanged.

## Consequences

- **Easier**: both agents get access to large hosted models without a subscription or hardware upgrade, and the local providers keep working unchanged.
- **Easier**: the change is additive and reversible — old generated configs remain valid after rollback.
- **Harder**: the free tier imposes unpublished session/weekly usage limits; the repo now depends on an external hosted service for cloud model availability.
- **Harder**: the API key is written in plaintext into generated home-dir config files; mitigated by home-dir permissions and the key being a revocable, app-scoped credential.
- **Follow-up**: the static catalog needs periodic Config.txt refreshes as Ollama adds or retires cloud models; free-tier eligibility is not officially published, so the pinned list may need adjustment after real usage.

Supersedes: none
