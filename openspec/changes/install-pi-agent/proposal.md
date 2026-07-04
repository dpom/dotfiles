## Why

Pi is a coding agent CLI that provides an interactive terminal-based AI coding assistant. Installing it on both machines brings a powerful, modern coding agent workflow to the developer's environment alongside existing tools like opencode and gemini.

## What Changes

- Add `pkgs.pi-coding-agent` at v0.80.3 to both `mary` and `bob` via a new Home Manager module
- Create `modules/home/pi.nix` with `dpom-pi.enable` toggle
- Register the module in `modules/home/default.nix` imports
- Enable `dpom-pi` in `hosts/mary/home.nix` and `hosts/bob/home.nix`
- Build the package at the desired version using `pkgs.buildNpmPackage` since nixpkgs only has v0.75.4

## Capabilities

### New Capabilities
- `pi-coding-agent`: Install and configure the pi coding agent CLI on both hosts

### Modified Capabilities


## Impact

- `modules/home/pi.nix` — new Home Manager module
- `modules/home/default.nix` — add import
- `hosts/mary/home.nix` — enable `dpom-pi`
- `hosts/bob/home.nix` — enable `dpom-pi`
- The pi package will need to be built from source (npm build) at the pinned version
