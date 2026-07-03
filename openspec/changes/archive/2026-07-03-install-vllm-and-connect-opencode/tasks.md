## 1. Create vLLM NixOS module

- [x] 1.1 Create `modules/nixos/vllm.nix` with `dpom-vllm` options (enable, acceleration, rocmGfxOverride, model, port)
- [x] 1.2 Implement systemd service for vLLM with proper environment, user, cache paths
- [x] 1.3 Add ROCm hardware.graphics support when acceleration = "rocm" (same pattern as ollama.nix)
- [x] 1.4 Register the module in `modules/nixos/default.nix`

## 2. Update mary host configuration

- [x] 2.1 Edit `hosts/mary/nixos.nix`: replace `dpom-ollama` with `dpom-vllm` with ROCm acceleration
- [x] 2.2 Update firewall ports on mary: add 8000, remove 11434
- [x] 2.3 Remove or comment out `dpom-docker.enable` if no longer needed

## 3. Configure opencode provider

- [x] 3.1 Update `opencode.json` with per-machine OpenAI-compatible provider configuration
- [x] 3.2 Ensure provider routes to vLLM (port 8000) on mary and Ollama (port 11434) on bob

## 4. Tangle and apply

- [x] 4.1 Edit `Config.txt` with the vLLM module definition and mary host changes
- [x] 4.2 Run `ent generate` or `./bin/generate-admin` to tangle to .nix files
- [ ] 4.3 Run `ent verify-init` and `ent check-emacs` to check no Emacs config regressions
- [ ] 4.4 Apply on mary: `sudo nixos-rebuild switch --flake .#mary`
- [ ] 4.5 Verify vLLM service is running: `systemctl status vllm`
- [ ] 4.6 Verify API responds: `curl http://localhost:8000/v1/models`

## 5. Verify and archive

- [ ] 5.1 Run `openspec validate install-vllm-and-connect-opencode --type change --strict` before archive
- [ ] 5.2 Commit all changes and archive the change
