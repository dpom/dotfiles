# Heterogeneous Local LLM Inference Stack

## Status

Accepted

## Context

The dotfiles manage two NixOS machines with different hardware: mary (Framework AMD AI 300 laptop with ROCm-compatible iGPU) and bob (CPU-only desktop). Both previously ran Ollama for local LLM inference, but Ollama's llama.cpp backend underutilizes mary's GPU. OpenCode lacked a local provider configuration, defaulting to remote API calls.

A unified inference engine would simplify maintenance but would be suboptimal on at least one machine: vLLM's CPU backend is immature, while llama.cpp (Ollama) cannot leverage ROCm GPUs as efficiently as vLLM.

## Decision

Adopt a heterogeneous inference stack: vLLM with ROCm GPU acceleration on mary, Ollama (llama.cpp) on bob for CPU-only inference. Each machine runs the best-suited engine for its hardware.

- **mary**: vLLM as a NixOS systemd service with ROCm GPU passthrough, OpenAI-compatible API on port 8000
- **bob**: Ollama (unchanged) with CPU-only inference, OpenAI-compatible API on port 11434
- **OpenCode**: Per-machine provider configuration routing requests to the local endpoint

Both engines expose OpenAI-compatible APIs, allowing OpenCode and other tools to use the same client interface regardless of host.

## Consequences

- **Positive**: Each machine runs the most performant engine for its hardware.
- **Positive**: OpenAI-compatible API means no changes to OpenCode's provider interface between machines.
- **Positive**: Existing Ollama config on bob is untouched — no regressions for CPU workloads.
- **Negative**: Two engines to maintain and update instead of one. Configuration knowledge is split.
- **Negative**: vLLM's ROCm support for RDNA 3.5 iGPUs may require workarounds or GFX version overrides.
- **Follow-up**: Verify vLLM's nixpkgs build includes ROCm/HIP support on x86_64-linux; if not, fall back to Docker deployment on mary.
