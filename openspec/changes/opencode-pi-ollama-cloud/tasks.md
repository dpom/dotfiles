## 1. SOPS secret setup

- [ ] 1.1 Obtain an Ollama Cloud API key from `ollama.com/settings/keys`
- [ ] 1.2 Add the key encrypted to `secrets/secrets.yaml` as `ollama_cloud_api_key` via `sops --set '["ollama_cloud_api_key"] "<key>"' secrets/secrets.yaml`
- [ ] 1.3 Declare `ollama_cloud_api_key = {}` in the `sops.secrets` block of the home default module in `Config.txt` (tangles to `modules/home/default.nix`)

## 2. Config.txt module edits (tangle-first)

- [ ] 2.1 In the opencode module block of `Config.txt` (`:tangle modules/home/opencode.nix`): add an `ollama-cloud` provider to the template with `npm: "@ai-sdk/openai-compatible"`, `name: "Ollama Cloud"`, `options.baseURL: "https://ollama.com/v1"`, and a static free-tier model list (`gpt-oss:20b`, `gpt-oss:120b`, `nemotron-3-nano:30b`, `nemotron-3-super`, `gemma4:31b`, `qwen3.5:397b`, `deepseek-v4-flash:0731`, `deepseek-v4-flash:preview`, `minimax-m2.7`) with `limit.context`/`limit.output`
- [ ] 2.2 In the opencode activation script: inject the SOPS secret value (`config.sops.secrets.ollama_cloud_api_key.path`) into `provider.ollama-cloud.options.apiKey` via `jq --arg` during generation
- [ ] 2.3 In the opencode template: set top-level `"model": "ollama-cloud/gpt-oss:20b"` in the generated config
- [ ] 2.4 In the pi module block of `Config.txt` (`:tangle modules/home/pi.nix`): add an `ollama-cloud` provider to the template with `baseUrl: "https://ollama.com/v1"`, `api: "openai-completions"`, and a static free-tier model list (same models as 2.1) with `id`, `name`, `contextWindow`, `maxTokens`
- [ ] 2.5 In the pi activation script: inject the SOPS secret value into `providers.ollama-cloud.apiKey` via `jq --arg` during generation
- [ ] 2.6 Confirm the `ollama` and `lmstudio` providers in both templates remain byte-identical in structure to before the change

## 3. Tangle, apply, verify

- [ ] 3.1 Run `ent generate` (or `./bin/generate-admin`) to tangle `Config.txt` into the `.nix` modules
- [ ] 3.2 Run `home-manager switch` to regenerate `~/.config/opencode/opencode.json` and `~/.pi/agent/models.json`
- [ ] 3.3 Verify `~/.config/opencode/opencode.json` contains `ollama-cloud` with `baseURL`, static models, injected `options.apiKey`, and top-level `"model": "ollama-cloud/gpt-oss:20b"`
- [ ] 3.4 Verify `~/.pi/agent/models.json` contains `ollama-cloud` with `baseUrl`, static models, and injected `apiKey`
- [ ] 3.5 Smoke-test opencode with the default `ollama-cloud/gpt-oss:20b` model (successful response = cloud auth works)
- [ ] 3.6 Smoke-test the pi `ollama-cloud` provider with a cloud model
- [ ] 3.7 Verify pi `settings.json` default (`muse-glimmer:latest` on `ollama`) is unchanged and local providers still work
- [ ] 3.8 Confirm the API key does not appear anywhere in the repository (generated configs are outside git)

## 4. Validation and commit

- [ ] 4.1 Run `openspec validate opencode-pi-ollama-cloud --type change --strict`
- [ ] 4.2 Commit `Config.txt`, tangled `.nix` files, `secrets/secrets.yaml`, and the `openspec/changes/opencode-pi-ollama-cloud/` artifacts together
