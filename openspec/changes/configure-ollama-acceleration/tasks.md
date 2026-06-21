## 1. Create the dpom-ollama NixOS module

- [ ] 1.1 Add the ollama module source block in `Config.txt` (under a new `** Ollama module` section) with:
  - `dpom-ollama.enable` option (mkEnableOption)
  - `dpom-ollama.acceleration` option (enum [null "rocm"])
  - `dpom-ollama.rocmGfxOverride` option (nullable string, default null)
  - `dpom-ollama.loadModels` option (list of strings)
  - config block that configures `services.ollama`, `hardware.graphics`, and `users.users.ollama` based on acceleration mode (ROCm adds GPU groups, hardware.graphics extras, LD_LIBRARY_PATH; null = CPU-only)
- [ ] 1.2 Add `./ollama.nix` to `modules/nixos/default.nix` imports in `Config.txt`
- [ ] 1.3 Run `ent generate` and verify the generated `modules/nixos/ollama.nix` module file

## 2. Update Mary host config to use the new module

- [ ] 2.1 Replace inline ollama config in Mary's `Config.txt` source block with: `dpom-ollama.enable = true; dpom-ollama.acceleration = "rocm";` (no GFX override — native `gfx1150` ISA)
- [ ] 2.2 Verify the module covers Mary's firewall port 11434, `hardware.graphics` ROCm extras, and Ollama user groups
- [ ] 2.3 Add `rocmPackages.rocminfo` to `environment.systemPackages` in Mary's config for debugging
- [ ] 2.4 Run `ent generate` and verify `hosts/mary/nixos.nix`

## 3. Update Bob host config to use the new module (CPU-only)

- [ ] 3.1 Replace inline ollama config in Bob's `Config.txt` source block with: `dpom-ollama.enable = true; dpom-ollama.loadModels = ["gemma3:12b"];` (no acceleration — CPU mode)
- [ ] 3.2 Run `ent generate` and verify `hosts/bob/nixos.nix`

## 4. Verify and deploy

- [ ] 4.1 Run `ent check-emacs` to validate config integrity
- [ ] 4.2 Apply to Mary: `home-manager switch -b backup --flake .#dan@mary && sudo nixos-rebuild switch --flake .#mary`
- [ ] 4.3 On Mary, run `rocminfo` and `ollama list` to verify GPU is detected; run a model and check `ollama ps` to confirm GPU inference
- [ ] 4.4 Apply to Bob: `home-manager switch -b backup --flake .#dan@bob && sudo nixos-rebuild switch --flake .#bob`
- [ ] 4.5 On Bob, run `ollama list` and `ollama ps` to verify service is running (CPU-only)
