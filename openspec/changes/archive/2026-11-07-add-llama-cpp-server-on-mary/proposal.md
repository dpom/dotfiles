## Why

Mary has a Radeon 890M with ROCm support and 46 GiB of shared memory, but local inference currently depends on Ollama. Ollama is convenient for model management, yet it does not provide the same control over llama.cpp server options, GGUF quantization, or OpenAI-compatible tool-calling behavior. A localhost-only llama.cpp endpoint with a code-focused GGUF gives opencode and gptel a dedicated coding model while keeping Ollama available for existing chat and agent workflows.

## What Changes

- Add a `dpom-llama-cpp` NixOS module in `Config.txt` that tangles to `modules/nixos/llama-cpp.nix`.
- Enable the module only on `mary`, with ROCm support for `gfx1150`, bound to `127.0.0.1:8080`; do not open a firewall port.
- Serve `Qwen3-Coder-30B-A3B-Instruct` from a service-readable GGUF, preferring `UD-Q4_K_XL` (~16.5 GiB) or `Q4_K_M` (~17.3 GiB), with bounded context and a single slot so it coexists with Ollama.
- Keep `dpom-ollama` enabled on mary and bob; do not change Ollama's port, model preloading, or ROCm acceleration.
- Add a `llama-cpp` OpenAI-compatible provider to the generated opencode config with a static model entry using the configured alias, while preserving the existing `ollama`, `lmstudio`, and `ollama-cloud` providers.
- Add a gptel backend and preset for the llama.cpp endpoint, while preserving the existing `Ollama` backend and presets.
- Record the ROCm version caveat and fallback path, Vulkan or a newer llama.cpp, in the change design and tasks.

## Capabilities

### New Capabilities
- `llama-cpp-server`: NixOS-managed llama.cpp server on mary with ROCm acceleration, service-readable GGUF provisioning, localhost-only OpenAI-compatible API, and bounded memory coexistence with Ollama.
- `llama-cpp-client-integration`: OpenCode provider and gptel backend/preset routing to the llama.cpp endpoint without changing existing Ollama client behavior.

### Modified Capabilities
- None. Existing Ollama, OpenCode provider, and gptel behavior specifications remain in force.

## Impact

- **Modified source**: `Config.txt` for the mary host block, module imports, and a new llama.cpp module tangle section; `Emacs.txt` for the gptel backend and preset.
- **Generated files**: `modules/nixos/llama-cpp.nix`, `modules/nixos/default.nix`, `hosts/mary/nixos.nix`, `modules/home/opencode.nix`, and `modules/home/emacs/init.el`.
- **Nix dependencies**: `pkgs.llama-cpp` with `rocmSupport = true`, `rocmPackages`, and `rocmGpuTargets = [ "gfx1150" ]`. Mary already enables `hardware.graphics` through `dpom-ollama`.
- **Storage**: 16.5-18.6 GB for the model, plus cache, under `/var/lib/llama-cpp` or `/var/cache/llama-cpp`. Models under `/home` are not readable because the service sets `ProtectHome=true`. Disk has 202 GB free.
- **Memory**: llama.cpp shares 46 GiB with the running Ollama service. Context length and slot count must be bounded, and total RSS must be verified during rollout.
- **Network**: Port 8080 is localhost-only. No firewall change is required.
- **Risk**: The pinned nixpkgs `llama-cpp` b9190 predates the HIP `prop.integrated` regression and its revert, so it should use the safe path but is older. Smoke-test output quality after deployment. If ROCm output is corrupted or too slow, use Vulkan or bump llama.cpp.
- **Fallback model**: `Qwen3.8-27B` `Q4_K_M` if Qwen3-Coder quality is insufficient, accepting roughly 4-6 t/s decode on this iGPU.
- **Secrets**: None. The endpoint is unauthenticated but bound to localhost.
