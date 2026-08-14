## Why

Opencode and Pi currently only expose local providers (Ollama on `localhost:11434`, LM Studio on `localhost:1234`), capping agent quality at whatever fits on the host GPU. Ollama Cloud provides a free tier of hosted open models reachable through an OpenAI-compatible API, so both tools can use much larger models without a paid subscription or upgraded hardware.

## What Changes

- Add an `ollama-cloud` provider entry to the OpenCode config template (`modules/home/opencode.nix`) pointing at `https://ollama.com/v1` with the full free-tier model catalog statically listed and API-key authentication.
- Add an `ollama-cloud` provider entry to the Pi config template (`modules/home/pi.nix`) pointing at `https://ollama.com/v1` with the same static model catalog and API-key authentication.
- Add a SOPS secret `ollama_cloud_api_key` and inject it into both generated configs at activation time.
- Set a default model for OpenCode (`ollama-cloud/<free-tier model>`). Pi's default provider/model (`muse-glimmer:latest` on local Ollama) is left unchanged.
- Keep the existing local `ollama` and `lmstudio` providers fully intact (non-breaking).

## Capabilities

### New Capabilities
- `opencode-ollama-cloud`: OpenCode gains an `ollama-cloud` provider (static free-tier model list, SOPS-sourced API key, OpenAI-compatible endpoint at `https://ollama.com/v1`) and a default model pointing at a cloud model, without disturbing the local `ollama`/`lmstudio` providers.
- `pi-ollama-cloud`: Pi gains an `ollama-cloud` provider (static free-tier model list, SOPS-sourced API key, base URL `https://ollama.com/v1`) alongside the existing local providers, without changing Pi's default provider/model.

### Modified Capabilities
<!-- None: existing requirement scenarios in opencode-lmstudio-provider and pi-coding-agent remain valid; no behavior of the local providers is altered. -->

## Impact

- `Config.txt` — Org source that tangles `modules/home/opencode.nix` and `modules/home/pi.nix`; both module blocks need the cloud provider added (literate-tangle-first workflow, then `ent generate`).
- `modules/home/opencode.nix` — template and activation script gain the `ollama-cloud` provider, static model list, default model, and secret injection.
- `modules/home/pi.nix` — template and activation script gain the `ollama-cloud` provider, static model list, and secret injection.
- `modules/home/default.nix` — `sops.secrets` gains `ollama_cloud_api_key` (access via `config.sops.secrets.ollama_cloud_api_key.path`).
- `secrets/secrets.yaml` — add the encrypted `ollama_cloud_api_key` value (never committed in plaintext).
- Generated runtime outputs: `~/.config/opencode/opencode.json` and `~/.pi/agent/models.json` (regenerated at `home-manager switch`).
- Model naming: the direct cloud API resolves model names without the local `:cloud` suffix (e.g. `gpt-oss:120b`); exact IDs must be resolved against `https://ollama.com/api/tags` during design.
- External dependency: free-tier usage is subject to Ollama's unpublished session/weekly usage limits; no subscription required.
