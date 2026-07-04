## 1. Module Definition

- [x] 1.1 Add `pi-coding-agent` package derivation using `pkgs.buildNpmPackage` to `Config.txt`
- [x] 1.2 Add `dpom-pi.enable` module option and config to `Config.txt`
- [x] 1.3 Add `./pi.nix` import to the home manager imports section in `Config.txt`
- [x] 1.4 Run `ent generate` or `./bin/generate-admin` to tangle the module into `modules/home/pi.nix` and `modules/home/default.nix`

## 2. Host Configuration

- [x] 2.1 Add `dpom-pi.enable = true;` to `mary` host config in `Config.txt`
- [x] 2.2 Add `dpom-pi.enable = true;` to `bob` host config in `Config.txt`
- [x] 2.3 Run `ent generate` to tangle host configs into `hosts/mary/home.nix` and `hosts/bob/home.nix`

## 3. Apply and Verify

- [x] 3.1 Run `home-manager switch --flake .#dan@mary` on mary
- [ ] 3.2 Run `home-manager switch --flake .#dan@bob` on bob (can't apply from mary)
- [x] 3.3 Verify `pi --version` reports `0.80.3` on both hosts (verified on mary)
- [x] 3.4 Run `openspec validate install-pi-agent --type change --strict`
- [x] 3.5 Commit both `Config.txt` source changes and tangled `.nix`/`.el` generated files
