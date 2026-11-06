# Cache llama.cpp GGUF Models at Runtime Instead of Pinning Them in the Nix Store

## Status

Accepted

## Date

2026-11-06

## Context

The new llama.cpp service on mary serves `Qwen3-Coder-30B-A3B-Instruct` from a GGUF that is roughly 16.45 GiB. The repo pins tool binaries to exact GitHub releases (ADR-0001 and ADR-0008), but model weights are a different artifact class: they are large, change less predictably, and are often swapped for quality or performance reasons.

The NixOS llama.cpp module supports two relevant paths:

- A pinned model path through `services.llama-cpp.model`, which could be a `fetchurl` fixed-output derivation in the Nix store.
- A `services.llama-cpp.modelsPreset` entry with Hugging Face repository and file keys, which the service downloads into `LLAMA_CACHE`.

The service runs with `ProtectHome=true`, so a model under `/home` is not an option. It already provides `StateDirectory=llama-cpp`, `CacheDirectory=llama-cpp`, and `LLAMA_CACHE=/var/cache/llama-cpp`.

Considered options:

- **Pin the GGUF with `fetchurl`.** Reproducible and hash-checked, but adds a 16.45 GiB fixed-output path to the Nix store, increases deployment weight, and requires a hash change for every model or quantization change.
- **Manual download into `/var/lib/llama-cpp`.** Service-readable, but requires a custom downloader and still needs a separate pinning decision.
- **Runtime Hugging Face cache through `modelsPreset`.** Chosen because it keeps the model out of the Nix store, uses the service's existing cache directory, and makes quantization changes a configuration change.

## Decision

Provision llama.cpp GGUFs through `services.llama-cpp.modelsPreset` and the service's `/var/cache/llama-cpp` cache. Do not pin the model in the Nix store for the first implementation.

The module will expose the Hugging Face repository, file, and alias so the model can be changed without editing generated files. The first model is `unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF`, preferring `Qwen3-Coder-30B-A3B-Instruct-UD-Q4_K_XL.gguf` and allowing `Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf`.

This decision is about model weights only. It does not change the repo's in-force commitment to pin agent binaries such as Ollama and opencode.

## Consequences

- **Easier:** the Nix store and system closure do not carry a 16.45 GiB model file.
- **Easier:** changing quantization or model is a module option change and a cache download, not a hash update and rebuild.
- **Easier:** the service reads from a path it owns and can access under `ProtectHome=true`.
- **Harder:** the model file is not hash-pinned. Upstream can change the file without a corresponding change in this repo.
- **Harder:** the first start needs network access and a 16.45 GiB download, so the service can take a long time to become healthy.
- **Harder:** model cache cleanup is outside Nix garbage collection and must be handled separately.
- **Follow-up:** monitor the Hugging Face file and add a SHA-256-pinned downloader or `fetchurl` path if reproducibility becomes important.
- **Follow-up:** a `bin/update-llama-cpp` or model helper may be useful later. This ADR does not supersede any prior ADR.
