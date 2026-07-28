## 1. Package Definition

- [ ] 1.1 Create `pkgs.buildNpmPackage` derivation for oh-my-pi from `github:can1357/oh-my-pi` at a pinned version
- [ ] 1.2 Verify `omp --version` works after build
- [ ] 1.3 Wrap binary with PATH dependencies (ripgrep, fd) in `postFixup`

## 2. Module Structure

- [ ] 2.1 Create `modules/home/oh-my-pi.nix` with `dpom-oh-my-pi.enable` option
- [ ] 2.2 Add module import to `modules/home/default.nix`

## 3. Config Generation

- [ ] 3.1 Create YAML config template with Ollama, LM Studio, Anthropic, and OpenAI provider entries
- [ ] 3.2 Create `generate-omp-config` script that queries Ollama and LM Studio for dynamic model discovery
- [ ] 3.3 Add activation hook to run `generate-omp-config` at `home-manager switch` time

## 4. Shell Completions

- [ ] 4.1 Add activation hook to generate bash completions and append `eval "$(omp completions bash)"` to `~/.bashrc` (idempotent)
- [ ] 4.2 Add activation hook to generate zsh completions and append `eval "$(omp completions zsh)"` to `~/.zshrc` (idempotent)
- [ ] 4.3 Add activation hook to generate fish completions at `~/.config/fish/completions/omp.fish`

## 5. Host Enablement

- [ ] 5.1 Enable `dpom-oh-my-pi.enable = true` in `hosts/mary/home.nix`
- [ ] 5.2 Enable `dpom-oh-my-pi.enable = true` in `hosts/bob/home.nix`

## 6. Literate Org-mode

- [ ] 6.1 Add module definition to `Config.txt` (not edit generated `.nix` directly)
- [ ] 6.2 Run `ent generate` to tangle `Config.txt` to generated files
- [ ] 6.3 Commit both `Config.txt` source and generated `.nix` files

## 7. Validation

- [ ] 7.1 Run `home-manager switch` on mary and verify `omp --version` works
- [ ] 7.2 Run `home-manager switch` on bob and verify `omp --version` works
- [ ] 7.3 Verify `omp completions bash` generates valid output
- [ ] 7.4 Verify existing Pi module still works (`pi --version`)
- [ ] 7.5 Run `openspec validate install-oh-my-pi --type change --strict`
