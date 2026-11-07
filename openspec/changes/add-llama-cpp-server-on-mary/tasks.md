## 1. Add the llama.cpp NixOS module source

- [x] 1.1 Add the `dpom-llama-cpp` module section to `Config.txt` with options `enable`, `acceleration`, `modelAlias`, `hfRepo`, `hfFile`, `contextLength`, `parallel`, `maxModels`, `host`, `port`, and `extraFlags`.
- [x] 1.2 Implement the ROCm override in the module: `pkgs.llama-cpp.override` with `rocmSupport = true`, `rocmPackages = pkgs.rocmPackages`, and `rocmGpuTargets = [ "gfx1150" ]`.
- [x] 1.3 Add `hardware.graphics` packages (`rocmPackages.clr.icd`, `rocmPackages.clr`, `rocmPackages.rocminfo`) and set `systemd.services.llama-cpp.serviceConfig.SupplementaryGroups = [ "render" ]`.
- [x] 1.4 Configure `services.llama-cpp.modelsPreset` for `Qwen3-Coder-30B-A3B-Instruct` using `unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF`, default `UD-Q4_K_XL` with `Q4_K_M` override, alias `qwen3-coder-30b-a3b-instruct`, `jinja = "on"`, and the documented sampling parameters.
- [x] 1.5 Add bounded server flags: `--ctx-size`, `--parallel`, `--models-max`, `--n-gpu-layers 999`, `--cache-type-k q8_0`, `--cache-type-v q8_0`, and `--no-webui`.
- [x] 1.6 Wire the module import in `Config.txt` and enable `dpom-llama-cpp.enable = true` for mary only; leave bob unchanged.

## 2. Add client integration source changes

- [x] 2.1 Add the static `llama-cpp` provider to the opencode template in `Config.txt` using `@ai-sdk/openai-compatible`, base URL `http://127.0.0.1:8080/v1`, and the `qwen3-coder-30b-a3b-instruct` model with `65536` context and `16384` output limits.
- [x] 2.2 Confirm the existing `ollama`, `lmstudio`, and `ollama-cloud` providers and the default `opencode/big-pickle` model remain unchanged.
- [x] 2.3 Add the `llama.cpp` gptel backend to `Emacs.txt` targeting `localhost:8080` with streaming and the `qwen3-coder-30b-a3b-instruct` model.
- [x] 2.4 Add the `llama-cpp` gptel preset selecting the `llama.cpp` backend and model, and confirm the `Ollama` backend, existing presets, and default backend remain unchanged.

## 3. Tangle and review generated configuration

- [x] 3.1 Run `ent generate` or `./bin/generate-admin` to tangle `Config.txt` and `Emacs.txt`.
- [x] 3.2 Inspect the generated diffs for `modules/nixos/llama-cpp.nix`, `modules/nixos/default.nix`, `hosts/mary/nixos.nix`, `modules/home/opencode.nix`, and `modules/home/emacs/init.el`.
- [x] 3.3 Validate the generated opencode JSON configuration.
- [x] 3.4 Run `ent verify-init`, parse the generated `init.el`, and evaluate the NixOS and home configurations to confirm the generated configuration is valid.

## 4. Deploy and smoke-test the server on mary

- [x] 4.1 Rebuild mary with `sudo nixos-rebuild switch --flake .#mary` (or the repo `ent update-system` path).
- [x] 4.2 Watch `journalctl -u llama-cpp -f` through the first model download and startup; confirm the model is cached under `/var/cache/llama-cpp` and not read from `/home`.
- [x] 4.3 Verify `GET /health` reports ready and `GET /v1/models` lists `qwen3-coder-30b-a3b-instruct`.
- [x] 4.4 Verify a non-streaming and a streaming chat completion against `/v1/chat/completions`, and verify a request with tool definitions returns a tool call.
- [x] 4.5 Verify the API is localhost-only: a request from bob to mary port 8080 is refused or times out, and no firewall port is opened for llama.cpp.
- [x] 4.6 Confirm Ollama remains reachable on `127.0.0.1:11434` while llama.cpp runs.
- [x] 4.7 Confirm the service logs report a ROCm device and that `HSA_OVERRIDE_GFX_VERSION` is not set.
- [x] 4.8 Send a smoke prompt and confirm coherent output; if output is corrupted, switch to Vulkan or a newer llama.cpp build before accepting the deployment.
- [x] 4.9 Monitor memory with `free -h` and `rocm-smi` while both services are active; fall back to `contextLength = 32768` with f16 KV cache or `Q4_K_M` if memory is too tight.

## 5. Verify client integration on mary

- [x] 5.1 Run `home-manager switch`, validate the regenerated `~/.config/opencode/opencode.json`, and exercise the `llama-cpp` provider in opencode.
- [x] 5.2 Exercise the gptel `llama-cpp` preset and confirm the default `Ollama` backend still works.
- [x] 5.3 Confirm the server, opencode provider, and gptel backend all use the `qwen3-coder-30b-a3b-instruct` alias.

## 6. Final validation

- [x] 6.1 Run `openspec validate add-llama-cpp-server-on-mary --type change --strict` and resolve any reported issues.
- [x] 6.2 Review the change against the specs and record any follow-up (GGUF pinning, quantization choice, context size, or ADR updates) before archive.

## Follow-ups

- Pin the GGUF by SHA-256 or a pinned downloader if reproducibility becomes important.
- Decide whether `UD-Q4_K_XL` or `Q4_K_M` is the default after measuring ROCm quality and throughput.
- Decide whether to keep 65,536 context with q8_0 KV cache or move to 32,768 with f16 after measuring memory beside Ollama.
- No in-force ADR needs supersession. If llama.cpp itself is pinned later, follow ADR-0001/ADR-0008 and add a new ADR.
