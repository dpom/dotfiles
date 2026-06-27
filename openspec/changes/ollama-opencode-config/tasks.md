## 1. OpenCode Provider Block in Home Manager

- [x] 1.1 Add `provider.ollama` block to the Home Manager-managed `opencode.jsonc` generation in `Config.txt`
- [x] 1.2 Declare initial model list with at least one model so the provider appears
- [x] 1.3 Set `"ollama"` as the default `model` in the config
- [x] 1.4 Run `./bin/generate-admin` and verify `~/.config/opencode/opencode.jsonc` is regenerated

## 2. Dynamic Model Discovery

- [x] 2.1 Create `generate-opencode-config` (inline `pkgs.writeShellApplication` in the Nix module) that queries the Ollama HTTP API (`http://localhost:11434/api/tags`) and produces the config
- [x] 2.2 Wire `generate-opencode-config` as a `home.activation` hook (runs every `home-manager switch`)
- [x] 2.3 Create standalone `bin/update-opencode-models` as a convenience script using `ollama list` for manual updates
- [x] 2.4 Test: add a model in Ollama, run `home-manager switch`, confirm it appears in OpenCode's `/models`

## 3. Verify on Both Hosts

- [x] 3.1 Run `home-manager switch` on `mary` and confirm OpenCode connects to Ollama
- [x] 3.2 Run `home-manager switch` on `bob` and confirm OpenCode connects to Ollama
- [x] 3.3 Commit all changes (Config.txt + generated .nix files)
