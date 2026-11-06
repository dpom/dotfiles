# Add llama.cpp as a Second Local Inference Runtime on mary

## Status

Accepted

## Date

2026-11-06

## Context

Mary is the only host with a usable local GPU: a Radeon 890M at `gfx1150` with 46 GiB of shared memory. Ollama already runs there with ROCm on `127.0.0.1:11434` and serves the existing opencode and gptel workflows.

Ollama is convenient for model management, but it exposes less control over llama.cpp server flags, GGUF selection, and OpenAI-compatible tool-calling behavior. A code-focused local model needs a dedicated endpoint with predictable context, slot, and sampling settings. `Qwen3-Coder-30B-A3B-Instruct` at Q4 fits in roughly 16.5 GiB, so it can coexist with Ollama in shared memory, especially because Ollama unloads idle models under its default keep-alive.

Considered options:

- **Ollama only.** Keeps one runtime but does not provide the llama.cpp server controls the code model needs.
- **vLLM.** Strong throughput for supported models, but a heavier service and a poorer fit for GGUF quantizations and the available shared-memory budget.
- **LM Studio.** Good interactive control, but an external application rather than a declarative NixOS service.
- **llama.cpp server.** Chosen because it supports GGUF, OpenAI-compatible endpoints, tool calls through Jinja templates, a nixpkgs NixOS module, ROCm builds, and localhost binding.

## Decision

Add a `dpom-llama-cpp` NixOS module and enable it only on mary. The service will:

- Use `pkgs.llama-cpp` with ROCm support targeted at `gfx1150`.
- Bind to `127.0.0.1:8080` and leave the firewall closed.
- Serve one code-focused GGUF, `Qwen3-Coder-30B-A3B-Instruct`, with one slot and a bounded context.
- Run alongside Ollama, which keeps its existing package, models, port, and ROCm configuration.
- Expose the endpoint to opencode through a static provider and to gptel through a dedicated backend and preset, while preserving existing defaults.

This does not replace Ollama. It establishes llama.cpp as a second local inference runtime for workloads that need direct GGUF and server control.

## Consequences

- **Easier:** opencode and gptel gain a dedicated local coding model with explicit context, slot, and tool-call settings.
- **Easier:** the endpoint is localhost-only and needs no API key or firewall change.
- **Easier:** Ollama remains available for existing models and cloud integration.
- **Harder:** two inference services now compete for the same 46 GiB of shared memory. Context, slots, and model count must stay bounded.
- **Harder:** mary carries an extra NixOS service, a 16.5 GiB model download, and client-specific configuration.
- **Harder:** ROCm support on `gfx1150` must be smoke-tested. If output is corrupted or too slow, Vulkan or a newer llama.cpp build is the fallback.
- **Follow-up:** measure memory and throughput after deployment, then decide whether 65K context or a smaller context is the right default.
- **Follow-up:** ADR-0010 records the model provisioning choice. This ADR does not supersede any prior ADR.
