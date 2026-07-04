## 1. Module Definition

- [ ] 1.1 Add `pi-coding-agent` package derivation using `pkgs.buildNpmPackage` to `Config.txt`
- [ ] 1.2 Add `dpom-pi.enable` module option and config to `Config.txt`
- [ ] 1.3 Add `./pi.nix` import to the home manager imports section in `Config.txt`
- [ ] 1.4 Run `ent generate` or `./bin/generate-admin` to tangle the module into `modules/home/pi.nix` and `modules/home/default.nix`

## 2. Host Configuration

- [ ] 2.1 Add `dpom-pi.enable = true;` to `mary` host config in `Config.txt`
- [ ] 2.2 Add `dpom-pi.enable = true;` to `bob` host config in `Config.txt`
- [ ] 2.3 Run `ent generate` to tangle host configs into `hosts/mary/home.nix` and `hosts/bob/home.nix`

## 3. Apply and Verify

- [ ] 3.1 Run `home-manager switch --flake .#dan@mary` on mary
- [ ] 3.2 Run `home-manager switch --flake .#dan@bob` on bob
- [ ] 3.3 Verify `pi --version` reports `0.80.3` on both hosts
- [ ] 3.4 Run `openspec validate install-pi-agent --type change --strict`
- [ ] 3.5 Commit both `Config.txt` source changes and tangled `.nix`/`.el` generated files
