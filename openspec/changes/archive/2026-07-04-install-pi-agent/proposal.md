## Why

Pi is a coding agent CLI that provides an interactive terminal-based AI coding assistant. Installing it on both machines brings a powerful, modern coding agent workflow to the developer's environment alongside existing tools like opencode and gemini.

## What Changes

- Add `pi-coding-agent` (v0.80.3) and `pi-acp` (v0.0.31) to both `mary` and `bob` via a new Home Manager module
- Create `modules/home/pi.nix` with `dpom-pi.enable` toggle, including both `buildNpmPackage` derivations and a `models.json` config for Ollama provider presets
- Register the module in `modules/home/default.nix` imports
- Enable `dpom-pi` in `hosts/mary/home.nix` and `hosts/bob/home.nix`
- Build both packages from source using `pkgs.buildNpmPackage` since nixpkgs has outdated versions

## Capabilities

### New Capabilities
- `pi-coding-agent`: Install and configure the pi coding agent CLI on both hosts
- `pi-acp`: Install the ACP adapter companion for agent-shell integration
- `.pi/agent/models.json`: Pre-configure Ollama provider with local model presets (gemma4, qwen2.5-coder, qwen3.5, llama3.1, llama3.2, TranslateGemma)

### Modified Capabilities


## Impact

- `modules/home/pi.nix` — new Home Manager module with inline derivations for both packages and models.json
- `modules/home/default.nix` — add import
- `hosts/mary/home.nix` — enable `dpom-pi`
- `hosts/bob/home.nix` — enable `dpom-pi`
- Both packages will be built from source (npm build) at pinned versions
