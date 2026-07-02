## Why

Optimize local LLM inference across both NixOS machines by using the best-suited engine per machine: vLLM with ROCm GPU acceleration on mary (Framework AMD AI 300 laptop) for maximum throughput, while keeping Ollama on bob (CPU-only desktop). OpenCode is currently unconfigured for local providers — this change connects it to the respective local endpoints.

## What Changes

- Add `modules/nixos/vllm.nix` — new NixOS module for vLLM as a systemd service with ROCm GPU passthrough
- Enable `dpom-vllm` on mary, disable `dpom-ollama` on mary (replacement)
- No change to bob's `dpom-ollama` config — stays CPU-only as-is
- Configure `opencode.json` with an OpenAI-compatible provider pointing to local vLLM (mary) or Ollama (bob)
- Open firewall port on mary for vLLM API (same pattern as existing port 11434 for Ollama on mary)

## Capabilities

### New Capabilities
- `vllm-service`: NixOS-managed vLLM inference server on mary with ROCm GPU acceleration, exposed as an OpenAI-compatible API
- `opencode-llm-integration`: OpenCode provider configuration to route requests to the local LLM endpoint on each machine

### Modified Capabilities
*(none — no existing spec files are changing behavior)*

## Impact

- **New file**: `modules/nixos/vllm.nix` (~60 lines, modeled after existing `ollama.nix`)
- **Modified file**: `hosts/mary/nixos.nix` — swap `dpom-ollama` for `dpom-vllm` with ROCm
- **Modified file**: `opencode.json` — add provider configuration
- **Nix dependencies**: `pkgs.vllm` (already in nixpkgs), `rocmPackages.*` (already in flake)
- **Network**: Port 8000 (vLLM default) opened on mary's firewall
- **Disk**: Model storage under `/var/lib/vllm/` or similar
