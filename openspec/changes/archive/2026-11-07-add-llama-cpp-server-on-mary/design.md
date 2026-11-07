## Context

Mary is a NixOS host with an AMD Ryzen AI 9 HX 370 and Radeon 890M (`gfx1150`), 46 GiB of shared memory, and an existing Ollama service on `127.0.0.1:11434` using ROCm. opencode and gptel currently use Ollama for local inference. The repo is literate: `Config.txt` and `Emacs.txt` are the sources, and `ent generate` or `./bin/generate-admin` produces the `.nix` and `.el` files.

This change adds a second, localhost-only inference endpoint using llama.cpp. The endpoint serves a code-focused GGUF model for opencode and gptel, while Ollama remains enabled and unchanged.

### Prior ADRs reviewed

All files under `adr/` were reviewed. The currently-in-force set is:

- ADR-0001: pin Ollama to GitHub release binaries.
- ADR-0003: add Ollama Cloud as a static hosted provider.
- ADR-0004: lift the pi version cap via vendored provider data, supersedes ADR-0002.
- ADR-0005: mirror upstream hermetic build order for pi.
- ADR-0007: never auto-patch prebuilt agent binaries.
- ADR-0008: pin opencode to prebuilt release assets and install completions, supersedes ADR-0006.

ADR-0002 and ADR-0006 are superseded and are historical context only. No in-force ADR conflicts with this design. The design follows ADR-0003's preference for static, deterministic client model catalogs and does not touch the pinned agent binaries covered by ADR-0001, ADR-0007, or ADR-0008.

### System diagram

Diagram choice: lightweight C4-inspired ASCII. This is a local host service with one external model source, so a container-level view is enough. Mermaid and deeper C4 levels would add maintenance without answering a real question.

```text
+------------------------------- mary (NixOS host) -------------------------------+
|                                                                                 |
|  dan --(opencode CLI)----+                                                       |
|                          |  HTTP 127.0.0.1:8080                                  |
|  dan --(Emacs/gptel)-----+---------> [llama.cpp server] --ROCm--> [Radeon 890M]  |
|                          |                  |                                    |
|                          |                  +--> /var/cache/llama-cpp (GGUF)     |
|                          |                                                       |
|  existing clients -------+---------> [Ollama server] ------> [Radeon 890M]        |
|                          |  HTTP 127.0.0.1:11434                                  |
|                                                                                 |
+---------------------------------------------------------------------------------+
             ^
             | first start downloads model
             |
  [Hugging Face: unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF]
```

- **Boundary:** all runtime components are on mary, and both inference APIs bind to localhost.
- **llama.cpp server:** owns GGUF loading, ROCm inference, the OpenAI-compatible API on 8080, and the model cache under `/var/cache/llama-cpp`.
- **Ollama server:** keeps its existing models, port, and ROCm configuration on 11434.
- **Clients:** opencode and gptel gain a second backend; existing Ollama routing stays in place.
- **External dependency:** Hugging Face supplies the model on first start. No other runtime external dependency is added.
- **Assumption:** the pinned nixpkgs `llama-cpp` b9190 predates the HIP `prop.integrated` regression and its revert, so it uses the safe path. This must be confirmed by a smoke test.

## Goals / Non-Goals

**Goals:**

- Add a `dpom-llama-cpp` NixOS module, tangled from `Config.txt`, that runs llama.cpp on mary with ROCm on `gfx1150`.
- Bind the API to `127.0.0.1:8080` and do not open a firewall port.
- Serve `Qwen3-Coder-30B-A3B-Instruct` from `unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF`, preferring `UD-Q4_K_XL` (~16.45 GiB) and allowing `Q4_K_M` (~17.29 GiB).
- Keep memory bounded so llama.cpp and Ollama can run together.
- Add a static `llama-cpp` provider to the generated opencode config and a `llama.cpp` backend plus preset to gptel.
- Preserve existing Ollama behavior, existing opencode providers, and existing gptel backends and presets.
- Keep `Config.txt` and `Emacs.txt` as the source of truth and commit generated files with their sources.

**Non-Goals:**

- Replace, disable, or reconfigure Ollama.
- Expose the llama.cpp endpoint to the LAN or add authentication.
- Enable the server on bob or add CPU-only support.
- Wire pi, oh-my-pi, or hermes to the new endpoint.
- Change the default opencode model or the default gptel backend.
- Add automatic llama.cpp or model update automation.
- Pin the model weights by hash in the first implementation.
- Guarantee the model's full 256K context or a specific throughput.

## Decisions

### 1. Use a thin `dpom-llama-cpp` wrapper around `services.llama-cpp`

The module will be written in `Config.txt` and tangled to `modules/nixos/llama-cpp.nix`. It will expose a small option surface and delegate service management to the nixpkgs module.

Planned options:

- `enable`: boolean.
- `acceleration`: `null` or `"rocm"`; mary sets `"rocm"`.
- `modelAlias`: default `"qwen3-coder-30b-a3b-instruct"`.
- `hfRepo`: default `"unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF"`.
- `hfFile`: default the `UD-Q4_K_XL` file, with `Q4_K_M` as an override.
- `contextLength`: default `65536`.
- `parallel`: default `1`.
- `maxModels`: default `1`.
- `host`: default `"127.0.0.1"`.
- `port`: default `8080`.
- `extraFlags`: additional llama-server flags.

Alternatives considered:

- **Set `services.llama-cpp` directly in `hosts/mary/nixos.nix`.** Rejected because the repo's `dpom-*` pattern keeps host files declarative and gives one place for ROCm package and permission handling.
- **Write a custom systemd unit.** Rejected because it duplicates the upstream module's hardening, state directories, cache directory, and restart policy.

### 2. Override the llama.cpp package for ROCm and grant render access

When `acceleration = "rocm"`, the module will set:

```nix
package = pkgs.llama-cpp.override {
  rocmSupport = true;
  rocmPackages = pkgs.rocmPackages;
  rocmGpuTargets = [ "gfx1150" ];
};
```

It will also enable `hardware.graphics`, add `rocmPackages.clr.icd`, `rocmPackages.clr`, and `rocmPackages.rocminfo` to `hardware.graphics.extraPackages`, and add `rocmPackages.rocminfo` to `environment.systemPackages`. This keeps the module self-contained even if Ollama is later disabled. Mary already gets these packages from `dpom-ollama`, and Nix deduplicates the lists.

The upstream NixOS module sets `DynamicUser = true` and `PrivateDevices = false` but does not grant the render group. The wrapper will add:

```nix
systemd.services.llama-cpp.serviceConfig.SupplementaryGroups = [ "render" ];
```

Ollama does the same for ROCm access to `/dev/dri/renderD*`. No `HSA_OVERRIDE_GFX_VERSION` will be set; mary uses native `gfx1150`.

Alternatives considered:

- **Vulkan instead of ROCm.** Rejected for the initial implementation because mary already runs ROCm successfully and native `gfx1150` avoids an override. Vulkan remains the fallback if the ROCm smoke test fails.
- **Rely on Ollama's ROCm packages only.** Rejected because the llama.cpp module should not silently break when Ollama is disabled.

### 3. Provision the model through `modelsPreset` and the llama.cpp cache

The module will set a single `services.llama-cpp.modelsPreset` entry:

```nix
{
  "Qwen3-Coder-30B-A3B-Instruct" = {
    hf-repo = "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF";
    hf-file = "Qwen3-Coder-30B-A3B-Instruct-UD-Q4_K_XL.gguf";
    alias = "qwen3-coder-30b-a3b-instruct";
    jinja = "on";
    temp = "0.7";
    top-p = "0.8";
    top-k = "20";
    min-p = "0.0";
    repeat-penalty = "1.05";
  };
}
```

The upstream module converts this to an INI file and passes `--models-preset`. The service already sets `StateDirectory=llama-cpp`, `CacheDirectory=llama-cpp`, `WorkingDirectory=/var/lib/llama-cpp`, and `LLAMA_CACHE=/var/cache/llama-cpp`. This satisfies `ProtectHome=true` and keeps the 16.45 GiB model out of the Nix store. The first start downloads the model; later starts reuse the cache.

The `hfFile` option allows `Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf` if the UD variant has a ROCm or quality problem.

Alternatives considered:

- **Pin the GGUF with `pkgs.fetchurl` and pass `services.llama-cpp.model`.** This is more reproducible, but it adds a 16.45 GiB fixed-output path to the Nix store, slows every evaluation and deployment that needs the model, and makes model changes require a hash update. Rejected for the first implementation, with a follow-up option to pin if reproducibility becomes important.
- **Use the existing `/home/dan/tmp/qwen2.5-coder-32b-instruct-abliterated-q3_k_l.gguf`.** Rejected because `ProtectHome=true` blocks `/home`, the model is older and lower quality, and the researched Qwen3-Coder model is the better fit.

### 4. Bound context, slots, and memory

The module will add server-level flags:

```nix
extraFlags = [
  "--ctx-size" (toString cfg.contextLength)
  "--parallel" (toString cfg.parallel)
  "--models-max" (toString cfg.maxModels)
  "--n-gpu-layers" "999"
  "--cache-type-k" "q8_0"
  "--cache-type-v" "q8_0"
  "--no-webui"
];
```

`--jinja` lives in the model preset so tool calls use the model's chat template. `--models-max 1` prevents the router from loading a second model. `--parallel 1` keeps one inference slot. The 65,536-token context with q8_0 KV cache is roughly 3 GiB for the KV cache, plus roughly 16.45 GiB for the model and about 1 GiB of overhead. Ollama's idle keep-alive is expected to unload its model when unused, leaving enough headroom in 46 GiB of shared memory.

Flash attention is not forced initially. It will be measured after deployment. If memory is tight, the first fallback is `contextLength = 32768` with f16 KV cache; the second is `Q4_K_M`.

Alternatives considered:

- **65,536 with f16 KV cache.** More predictable than q8_0, but roughly doubles KV memory. Kept as a fallback rather than the default.
- **32,768 by default.** Safer for coexistence, but reduces the context available to coding agents. Kept as a runtime override.
- **Let `fit` choose GPU layers.** Rejected because `--n-gpu-layers 999` gives predictable full offload for a model that fits comfortably.

### 5. Use a static OpenCode provider

The opencode template in `modules/home/opencode.nix`, tangled from `Config.txt`, will gain:

```json
"llama-cpp": {
  "npm": "@ai-sdk/openai-compatible",
  "name": "llama.cpp (local)",
  "options": {
    "baseURL": "http://127.0.0.1:8080/v1"
  },
  "models": {
    "qwen3-coder-30b-a3b-instruct": {
      "name": "Qwen3 Coder 30B A3B (local)",
      "limit": { "context": 65536, "output": 16384 }
    }
  }
}
```

The existing activation script only rewrites `provider.ollama.models`, `provider.lmstudio.models`, and `provider["ollama-cloud"].options.apiKey`, so the static `llama-cpp` entry survives regeneration. The default model stays `opencode/big-pickle`.

Alternatives considered:

- **Discover models from `/v1/models` at activation time.** Rejected because `home-manager switch` can run while the server is down, which would produce an empty model list. Static configuration also matches ADR-0003's approach for the cloud catalog.
- **Change the default opencode model to the local model.** Rejected because the proposal keeps existing defaults and adds the provider as an opt-in.

### 6. Add a dedicated gptel backend and preset

`Emacs.txt` will register a second OpenAI-compatible backend next to the existing Ollama backend:

```elisp
(gptel-make-openai "llama.cpp"
  :host "localhost:8080"
  :protocol "http"
  :endpoint "/v1/chat/completions"
  :stream t
  :models '((qwen3-coder-30b-a3b-instruct
             :description "Qwen3 Coder 30B A3B (local)"
             :capabilities (tool-use))))
```

No API key is set, so gptel does not send an `Authorization` header. The default backend remains `Ollama`. A new `llama-cpp` preset will select `:backend "llama.cpp"`, `:model 'qwen3-coder-30b-a3b-instruct`, require `llm-tool-collection`, and use the same tool-call settings as the existing local presets.

Alternatives considered:

- **Reuse the existing Ollama backend with a different host.** gptel backends are registered by name and host, and mixing hosts in one backend is unclear. A separate backend is explicit.
- **Replace the `codex` preset with the new backend.** Rejected because the proposal preserves existing presets and adds an opt-in path.

### 7. Keep the literate workflow

All source edits go into `Config.txt` and `Emacs.txt`. The generated files are:

- `modules/nixos/llama-cpp.nix`
- `modules/nixos/default.nix`
- `hosts/mary/nixos.nix`
- `modules/home/opencode.nix`
- `modules/home/emacs/init.el`

`ent generate` or `./bin/generate-admin` regenerates them. The generated files are committed with the source edits. No generated `.nix` or `.el` file is edited directly.

## Risks / Trade-offs

- **[ROCm b9190 output corruption]** -> Smoke-test a prompt for coherent output. If it fails, switch to Vulkan or bump llama.cpp to a build after the revert.
- **[Unpinned Hugging Face model file]** -> The model can change upstream without a hash change in this repo. Accept for the first implementation; add a pinned downloader or `fetchurl` if reproducibility becomes important.
- **[Memory pressure with Ollama]** -> One slot, one model, 65K q8_0 KV cache, and no Ollama reconfiguration. Fall back to 32K or `Q4_K_M` if total RSS is too high.
- **[First start downloads 16.45 GiB]** -> The service may take a long time to become healthy. Pre-download during the deployment window and monitor `journalctl -u llama-cpp`.
- **[DynamicUser cannot access GPU devices]** -> Add `SupplementaryGroups = [ "render" ]` and verify the service can open `/dev/kfd` and `/dev/dri/renderD128`.
- **[Router mode loads more than one model]** -> Set `--models-max 1` and use a preset with a single entry.
- **[Tool calls fail]** -> Verify `--jinja` and the model chat template with a direct `/v1/chat/completions` tool-call request before testing clients.
- **[Slow prefill on the 890M]** -> Keep the context moderate, rely on client-side context management, and measure prefill before raising the context above 65K.
- **[Static OpenCode model limit drifts from the server]** -> Keep the 65536/16384 limits in sync with `contextLength`; add a task to update both together.
- **[gptel sends an unexpected auth header]** -> Omit `:key` and verify the server receives unauthenticated localhost requests.

## Migration Plan

1. Add the `dpom-llama-cpp` module section and mary host block in `Config.txt`, plus the module import.
2. Add the static `llama-cpp` provider in the opencode template in `Config.txt`.
3. Add the `llama.cpp` gptel backend and preset in `Emacs.txt`.
4. Run `ent generate` or `./bin/generate-admin` and inspect the generated diffs.
5. Run `sudo nixos-rebuild switch --flake .#mary` or the repo's `ent update-system` path.
6. Watch `journalctl -u llama-cpp -f` through the first model download and startup.
7. Verify `/health`, `/v1/models`, a streaming chat completion, and a tool-call request on `127.0.0.1:8080`.
8. Verify `curl` to mary's port 8080 from bob fails and that `127.0.0.1:11434` still serves Ollama.
9. Run `home-manager switch` to regenerate `~/.config/opencode/opencode.json`, validate the JSON, and test the `llama-cpp` provider.
10. Run `ent check-emacs`, then test the gptel `llama-cpp` preset and confirm the default Ollama backend still works.
11. Monitor memory with `free -h` and `rocm-smi` while both services are active.

Rollback:

- Revert to the previous NixOS generation with `nixos-rebuild switch --rollback`, or remove `dpom-llama-cpp.enable` and redeploy.
- Revert the opencode and gptel source edits and regenerate their configs.
- Ollama is unaffected throughout.
- The model cache under `/var/cache/llama-cpp` can remain for a later retry or be removed manually.
- No database or user data migration is involved.

## Open Questions

- Should the GGUF be pinned by SHA-256 in a follow-up, instead of relying on the Hugging Face cache?
- Should the default quantization be `UD-Q4_K_XL` or `Q4_K_M` after ROCm performance and quality measurements?
- Should the default context stay at 65,536 with q8_0 KV cache, or drop to 32,768 with f16 KV cache for more memory headroom?
- Should pi, oh-my-pi, or hermes be wired to the endpoint in a later change?
- Should a `bin/update-llama-cpp` or model update helper be added?
- No in-force ADR needs supersession for this change. If the repo later decides to pin llama.cpp itself, ADR-0001 and ADR-0008 provide the pattern and a new ADR should record that decision.
