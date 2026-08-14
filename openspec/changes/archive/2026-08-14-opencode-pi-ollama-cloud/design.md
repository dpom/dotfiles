## Context

Both agent configs are generated at Home Manager activation time:

- `modules/home/opencode.nix` runs `generate-opencode-config`, which starts from a static template (`ollama` + `lmstudio` providers) and injects locally discovered models, writing `~/.config/opencode/opencode.json`.
- `modules/home/pi.nix` runs `generate-pi-config`, which does the same for `~/.pi/agent/models.json`.

Both modules are tangled from `Config.txt` (literate-first workflow). Secrets live in SOPS (`secrets/secrets.yaml`, declared via `sops.secrets` in `modules/home/default.nix`).

Ollama Cloud offers hosted open models over an OpenAI-compatible endpoint at `https://ollama.com/v1`, authenticated with an API key (no subscription required on the free tier). The live catalog at `https://ollama.com/api/tags` (unauthenticated) currently lists 18 models; direct-API names use no `:cloud` suffix (e.g. `gpt-oss:20b`). Free-tier eligibility is unpublished; community-verified usage bands put low/medium-band models on the free tier and high-band models on paid plans.

In-force ADRs: `0001-pin-ollama-to-github-release-binaries` (pins the local ollama daemon; coherent with a direct cloud endpoint — we do not depend on local ollama) and `0002-cap-pi-coding-agent` (caps pi at v0.80.3; implementation has since moved to v0.84.1 with vendored model data, so this ADR is effectively lifted in practice — see Open Questions).

## Goals / Non-Goals

**Goals:**
- Add a third `ollama-cloud` provider to the opencode and pi config templates, pointing at `https://ollama.com/v1`, with the full free-tier model catalog statically listed and API-key auth.
- Wire the API key through SOPS (`ollama_cloud_api_key`), injected into the generated configs at activation time.
- Set a default model for opencode (`ollama-cloud/gpt-oss:20b`).
- Keep the existing `ollama` and `lmstudio` providers byte-identical in behavior (non-breaking).

**Non-Goals:**
- Not using local ollama as a proxy for `:cloud` models (direct endpoint only).
- Not changing pi's default provider/model (`muse-glimmer:latest` stays).
- Not removing or altering existing local providers.
- Not migrating existing per-session model selections.
- No new provider SDK — reuse `@ai-sdk/openai-compatible` (opencode) and `openai-completions` (pi).

## Decisions

**D1: Direct cloud endpoint over local-ollama proxy.**
Use `https://ollama.com/v1` (OpenAI-compatible) as a first-class provider. Alternatives considered: (a) list `:cloud` models against `localhost:11434`, which works only when the local ollama daemon is running and signed in, and uses different model names (`gpt-oss:20b-cloud` vs `gpt-oss:20b`); (b) native `https://ollama.com/api`. The OpenAI-compatible `/v1` route is the smallest change to both tools' existing provider wiring (both already speak OpenAI-compatible for local providers).

**D2: Third provider `ollama-cloud`, leaving `ollama`/`lmstudio` untouched.**
The existing specs (`opencode-lmstudio-provider`, `pi-coding-agent`) require the local providers to survive; a separate provider makes the change additive and trivially reversible.

**D3: Static curated free-tier catalog, pinned in the template.**
Pin the free-tier-eligible subset of the live catalog (low + medium usage bands): `gpt-oss:20b`, `gpt-oss:120b`, `nemotron-3-nano:30b`, `nemotron-3-super`, `gemma4:31b`, `qwen3.5:397b`, `deepseek-v4-flash:0731`, `deepseek-v4-flash:preview`, `minimax-m2.7`. Alternatives: dynamic fetch of `/api/tags` at activation (would surface Pro-only models like `glm-5.1`, `kimi-k3`, `deepseek-v4-pro` that error on the free plan, and needs network during activation) and un-filtered static copy (same free-plan breakage). A deterministic, reviewable pin matches the repo's ADR-0001 ethos.

**D4: SOPS-sourced API key injected at build time, read at activation.**
`config.sops.secrets.ollama_cloud_api_key.path` is interpolated into the activation script; at runtime the script reads the decrypted file and injects it into the generated JSON (`options.apiKey` for opencode, `apiKey` for pi) via `jq --arg`. Alternatives: (a) relying on `OLLAMA_API_KEY` at runtime — leaves credential management to the user and out of the repo; (b) hardcoding — secret lands in git.

**D5: opencode default model via top-level `"model"`.**
`"model": "ollama-cloud/gpt-oss:20b"` in the generated config (opencode uses `<provider>/<model>` format). Chosen model is the low-usage, coding-oriented one so daily use stays inside free allowances. Pi's default is intentionally not touched.

**D6: Keep the config generated at activation (no home.file symlink).**
Preserves the existing discovery pattern (local models refresh every switch) and keeps the decrypted key out of the nix store. Trade-off: the key sits in plaintext home-dir config files (see Risks).

## Risks / Trade-offs

- [Free-tier limits are unpublished (session/weekly caps)] -> Default opencode to low-usage `gpt-oss:20b`; leave higher-band models selectable rather than default; monitor during early use.
- [Pro-only models would error if listed] -> Curated catalog excludes high/extra-high bands; catalog freshness handled by deliberate Config.txt edits, not blind dynamic sync.
- [API key in plaintext generated configs (`~/.config/opencode/opencode.json`, `~/.pi/agent/models.json`)] -> Mitigate with strict home-dir permissions; the key is an app-scoped, revocable credential; document that it is not committed (generated files are gitignored/untracked). Alternative (runtime env var) deferred.
- [Upstream catalog churn (tags like `deepseek-v4-flash:preview` move)] -> Pin in Config.txt; updating is a one-block edit + re-tangle; mismatch surfaces as a failed provider load, not a config error.
- [`options.apiKey` semantics for `@ai-sdk/openai-compatible` in opencode] -> Verify against the opencode provider schema during apply; fall back to an `env` mapping / `OLLAMA_API_KEY` export if unsupported.
- [ADR 0002 no longer matches implementation (pi v0.84.1 + vendored model data)] -> Not blocking this change; flagged for the adr step to record supersession.

## Migration Plan

1. Obtain an API key from `ollama.com/settings/keys`; add it encrypted: `sops --set '["ollama_cloud_api_key"] "<key>"' secrets/secrets.yaml`.
2. In `Config.txt`: declare `ollama_cloud_api_key` in the `sops.secrets` block of `modules/home/default.nix`; add the `ollama-cloud` provider + static model list + secret injection to both module blocks; add the opencode default `"model"`.
3. Run `ent generate` (or `./bin/generate-admin`) to tangle; commit `Config.txt` and the generated `.nix` files together.
4. `home-manager switch` regenerates both configs; verify with `curl https://ollama.com/api/chat`-style smoke test and a prompt through each agent.
5. Rollback: revert the commit and re-switch; previous configs are self-contained and remain valid (change is additive).

## Open Questions

- Exact free-tier eligibility of the 18 `/api/tags` models is not published; the curated D3 list assumes low/medium usage bands are free-usable. Confirm while signed in; adjust the pinned list if a model 401s/errors.
- Should `deepseek-v4-flash:preview` (a moving preview tag) be pinned, or dropped in favor of only `:0731`? (Design includes it; dropping is a one-line change.)
- Verify opencode honors `options.apiKey` for `@ai-sdk/openai-compatible`; if not, switch to provider `env` + `OLLAMA_API_KEY`.
- ADR 0002 (`0002-cap-pi-coding-agent`) appears superseded in practice — pi is at v0.84.1 with vendored `pi-model-data` — but no superseding ADR was recorded. The adr step should record the supersession.
