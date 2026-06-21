## 1. Create the dpom-ollama NixOS module

- [x] 1.1 Added ollama module source block in `Config.txt` (`** Ollama module`) with all `dpom-ollama` options and config
- [x] 1.2 Added `./ollama.nix` to `modules/nixos/default.nix` imports in `Config.txt`
- [x] 1.3 Tangled with `nix run nixpkgs#emacs-nox -- -Q --batch ...` — 44 code blocks, syntax verified

## 2. Update Mary host config to use the new module

- [x] 2.1 Replaced inline ollama config in Mary's `Config.txt` with `dpom-ollama.enable = true; dpom-ollama.acceleration = "rocm";` (no GFX override — native `gfx1150` ISA)
- [x] 2.2 Module covers hardware.graphics ROCm extras and Ollama user groups (firewall port 11434 stays in networking section)
- [x] 2.3 Module adds `rocmPackages.rocminfo` to `environment.systemPackages` when acceleration is "rocm"
- [x] 2.4 Tangled and verified `hosts/mary/nixos.nix` — clean

## 3. Update Bob host config to use the new module (CPU-only)

- [x] 3.1 Replaced inline ollama config in Bob's `Config.txt` with `dpom-ollama.enable = true; dpom-ollama.loadModels = ["gemma3:12b"];`
- [x] 3.2 Tangled and verified `hosts/bob/nixos.nix` — clean

## 4. Verify and deploy

- [x] 4.1 Syntax-checked all generated .nix files with `nix-instantiate --parse` — all OK
- [x] 4.2 Apply to Mary: `home-manager switch -b backup --flake .#dan@mary && sudo nixos-rebuild switch --flake .#mary`
- [x] 4.3 On Mary, run `rocminfo` and `ollama list` to verify GPU is detected; run a model and check `ollama ps` to confirm GPU inference
- [x] 4.4 Apply to Bob: `home-manager switch -b backup --flake .#dan@bob && sudo nixos-rebuild switch --flake .#bob`
- [x] 4.5 On Bob, run `ollama list` and `ollama ps` to verify service is running (CPU-only)
