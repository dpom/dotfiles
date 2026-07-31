## Why

The existing `pi-coding-agent` module installs Pi v0.80.3 from `earendil-works/pi`. oh-my-pi (`can1357/oh-my-pi`) is an actively maintained fork with significantly improved tool performance (hashline edits, native LSP/DAP, in-process ripgrep/glob), 40+ provider support, and first-class subagents. Switching provides a more capable coding agent with better token efficiency and broader provider compatibility for both local and cloud models.

## What Changes

- Add oh-my-pi (`can1357/oh-my-pi`) as a new Home Manager module alongside existing Pi
- oh-my-pi uses binary `omp`, config at `~/.omp/agent/` — no conflicts with existing `pi` binary
- New `dpom-oh-my-pi.enable` option (existing `dpom-pi.enable` unchanged)
- Config format: `models.yml` with dynamic model discovery for Ollama, LM Studio, and cloud providers
- Shell completions for bash, zsh, and fish
- Both agents can be enabled simultaneously on any host

## Capabilities

### New Capabilities
- `oh-my-pi-installation`: Install and configure the oh-my-pi CLI (`omp`) via Home Manager as a Nix package
- `oh-my-pi-providers`: Configure model providers (Ollama, LM Studio, cloud providers) with dynamic model discovery
- `oh-my-pi-completions`: Shell completions for bash, zsh, and fish

### Modified Capabilities
- (none — adding new module, existing Pi module unchanged)

## Impact

- `modules/home/oh-my-pi.nix`: New module file
- `modules/home/default.nix`: Add import for `oh-my-pi.nix`
- `hosts/mary/home.nix` and `hosts/bob/home.nix`: Enable `dpom-oh-my-pi.enable = true`
- `modules/home/pi.nix`: Unchanged
- Flake inputs: May add `oh-my-pi` as a flake input, or fetch from GitHub in the package derivation
