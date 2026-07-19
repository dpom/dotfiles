## 1. PI Agent — Add LM Studio provider to config template and activation script

- [x] 1.1 Add `lmstudio` provider entry to `piConfigTemplate` in `Config.txt` with `baseUrl: http://localhost:1234/v1`, `api: openai-completions`, `apiKey: lm-studio`, and `compat` flags
- [x] 1.2 Update `generatePiConfig` script in `Config.txt` to query `http://localhost:1234/v1/models`, transform returned models into PI agent format, and inject into `providers.lmstudio.models`
- [x] 1.3 Verify LM Studio query uses graceful failure (empty model list when unreachable)

## 2. OpenCode — Add LM Studio provider to config template and activation script

- [x] 2.1 Add `lmstudio` provider entry to `opencodeTemplate` in `Config.txt` with `baseURL: http://localhost:1234/v1`, `npm: @ai-sdk/openai-compatible`, `name: "LM Studio (local)"`
- [x] 2.2 Update `generateOpencodeConfig` script in `Config.txt` to query `http://localhost:1234/v1/models`, transform returned models into OpenCode V1 format, and inject into `provider.lmstudio.models`
- [x] 2.3 Verify LM Studio query uses graceful failure (empty models object when unreachable)

## 3. Tangle, apply, and verify

- [x] 3.1 Run `ent generate` or `./bin/generate-admin` to tangle `Config.txt` into updated `.nix` files
- [x] 3.2 Run `home-manager switch -b backup --flake .#dan@$(hostname)` to apply
- [x] 3.3 Inspect generated `~/.config/opencode/opencode.json` and `~/.pi/agent/models.json` to confirm both providers are present
