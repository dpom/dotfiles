# AGENTS.md — dpom/dotfiles

## Project Overview

Personal NixOS dotfiles using flakes, home-manager, and a literate Emacs configuration. Two hosts: `mary` (Framework laptop) and `bob` (desktop).

## Architecture

```
flake.nix          → Entry point (defines nixosConfigurations + homeConfigurations)
Config.txt         → Org mode → tangles to .nix files (host configs, modules, vars)
Emacs.txt          → Org mode → tangles to init.el, early-init.el, templates.eld
hosts/<name>/      → Machine-specific {nixos,home,hardware-configuration}.nix
modules/home/      → Home Manager modules (bash, emacs, git, sway, kitty, etc.)
modules/nixos/     → NixOS system modules (docker, nvidia, ollama, proton, etc.)
secrets/           → SOPS-encrypted secrets (secrets.yaml)
bin/               → Shell scripts (update-home, update-system, generate-admin, etc.)
```

## Key Conventions

- **Nix options:** `dpom-<module>.enable = true/false` (e.g., `dpom-bash.enable = true`)
- **Emacs Lisp:** `local/` prefix for custom functions; `use-package` for packages
- **Org files store as .txt:** `Config.txt` and `Emacs.txt` are Org mode files (not plain text)
- **Literate programming:** Always edit Org files, then tangle to regenerate .nix/.el files

## Essential Commands

### From Emacs (via `ent` task runner)
| Command | Description |
|---------|-------------|
| `ent generate` | Tangle Config.txt and Emacs.txt |
| `ent verify-init` | Check init.el for balanced parens |
| `ent check-emacs` | Full validation (tangle + verify + lock + run check) |
| `ent update-inputs` | `nix flake update` |
| `ent update-home` | `home-manager switch --flake .#dan@$(hostname)` |
| `ent update-system` | `sudo nixos-rebuild switch --flake .#<host>` |
| `ent nix-clean` | Garbage collect Nix store |

### From shell
```sh
# Generate/tangle configurations
./bin/generate-admin

# Apply home-manager config
home-manager switch -b backup --flake .#dan@$(hostname)

# Apply NixOS system config
sudo nixos-rebuild switch --flake .#<hostname>

# Update flake inputs
nix flake update
```

## Emacs Configuration Style

- `lexical-binding: t` on all .el files
- XDG dir vars defined at top of init.el
- `quiet!` macro silences noisy operations
- `define-repl` macro for REPL buffers
- `local/get-secret` for reading SOPS secrets
- `with-eval-after-load 'gptel` for tool definitions and presets
- `gptel-make-tool` for defining MCP-like tools available to AI
- `gptel-make-preset` for named AI interaction configurations
- `mcp-hub-servers` configured for clojure, github, duckduckgo, nixos, fetch, filesystem, sequential-thinking MCP servers

## Module Writing Guidelines

1. **Home Manager modules** go in `modules/home/<name>.nix` — import in `modules/home/default.nix`
2. **NixOS modules** go in `modules/nixos/<name>.nix` — import in `modules/nixos/default.nix`
3. **Option pattern:**
   ```nix
   options.dpom-<name>.enable = lib.mkEnableOption "...";
   config = lib.mkIf config.dpom-<name>.enable { ... };
   ```
4. **Host-specific configs:** `hosts/<name>/home.nix` enables modules, `hosts/<name>/nixos.nix` enables modules

## Secrets

- Managed via SOPS (Age key at `~/.ssh/id_sops_age`)
- Encrypted file: `secrets/secrets.yaml`
- Never commit unencrypted secrets
- Access via `config.sops.secrets.<name>` in Nix
- Access via `local/get-secret` in Emacs Lisp

## Testing / Validation

No formal test framework. Validation is done through:
- `ent verify-init` — checks Emacs init.el parenthetical balance
- `ent check-emacs` — full Emacs config smoke test
- `home-manager switch` — applies and reports errors
- `nixos-rebuild switch` — applies and reports errors

## Git Conventions

- Commit messages should describe the *why* (not just the *what*)
- Prefer tangle-first workflow: edit Org files → tangle → commit generated files
- Ignored: `*~`, `#*`, `eln-cache/`, `.direnv/`, `.sops.yaml`

## OpenSpec Git Discipline

- For OpenSpec propose/apply/verify/archive workflows, use the local `openspec-git-discipline` skill to enforce proposal commits before apply and merge-before-archive discipline.
