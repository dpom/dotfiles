# GEMINI CLI Project Context: .dotfiles

This file serves as the foundational mandate for all Gemini CLI interactions within this repository. It defines the architecture, conventions, and workflows that must be followed to ensure consistency and maintainability.

## Project Overview

This is a declarative, reproducible Nix-based dotfiles repository managed with **Nix Flakes**, **Home Manager**, and **NixOS**. It employs a literate configuration approach where key settings are tangled from Emacs.

## Core Architecture

- **Entry Point:** `flake.nix` defines `nixosConfigurations` and `homeConfigurations`.
- **Host Configurations:** Found in `hosts/<hostname>/`.
    - `nixos.nix`: Machine-specific NixOS settings.
    - `home.nix`: Machine-specific Home Manager settings.
    - `hardware-configuration.nix`: Auto-generated hardware specs.
- **Modules:** Reusable logic located in `modules/`.
    - `modules/nixos/`: System-level modules (drivers, services, core apps).
    - `modules/home/`: User-level modules (shell, editor, desktop environment).
- **Central Variables:** `vars.nix` defines the `user-vars` option set (e.g., `user`, `email`, `timezone`), which should be used throughout the configuration for consistency.
- **Secrets Management:** **SOPS-Nix** is used. Secrets are defined in `secrets/secrets.yaml` and integrated via `sops.nix`.
- **Styling:** **Stylix** is used for unified system and application theming.

## Development Workflows

### 1. Configuration Changes
- **Literate Config:** Modifications to core Emacs or system settings should often start in `Config.txt` or `Emacs.txt` and then be tangled using Emacs.
- **Nix Modules:** Add or modify `.nix` files in `modules/` for shared logic. Ensure they are imported in the corresponding `default.nix` (either `modules/nixos/default.nix` or `modules/home/default.nix`).

### 2. Deployment
- **System Update:** `sudo nixos-rebuild switch --flake .#<hostname>`
- **Home Update:** `home-manager switch --flake .#<user>@<hostname>` (or use `dan@<hostname>` as defined in `flake.nix`).
- **Binary Utilities:** Use scripts in `bin/` for common tasks (e.g., `update-system`, `update-home`).

### 3. Adding Secrets
- Edit `secrets/secrets.yaml` using `sops`.
- Reference the secret in Nix via `config.sops.secrets."secret_name".path`.

## Technical Standards & Conventions

- **Variable Access:** Always prefer using `config.user-vars.<var>` over hardcoding user-specific values.
- **Module Imports:** Follow the established pattern of importing modules in `modules/<type>/default.nix` to keep host-specific files clean.
- **File Naming:** Use kebab-case for `.nix` files (e.g., `hardware-configuration.nix`).
- **Code Style:** Adhere to standard Nix formatting (e.g., as produced by `nixfmt` or `nixpkgs-fmt`).
- **Safety:** NEVER commit unencrypted secrets. Ensure `id_sops_age` is protected and correctly referenced in `sops.nix`.

## Gemini CLI Instructions

- **Context Awareness:** Always check `vars.nix` before suggesting changes involving user names, paths, or hostnames.
- **Tooling:** When suggesting updates, prioritize the use of the `bin/` scripts if they cover the requested action.
- **Documentation:** Maintain the literate nature of the project by updating `README.org` or the `.txt` source files if the change warrants it.
