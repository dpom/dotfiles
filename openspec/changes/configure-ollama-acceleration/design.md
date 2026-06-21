## Context

Ollama is currently configured inline in each host's `nixos.nix`. Mary has ROCm config that doesn't work; Bob has no acceleration. There is no shared module. The existing `modules/nixos/ollama.nix` is a package override (not a NixOS module) used only by Bob. Mary uses `pkgs.ollama-rocm` from nixpkgs directly.

The repository follows the `dpom-<name>.enable` module pattern. Nvidia support exists as `dpom-nvidia` but isn't enabled on any host (Bob's GPU is Intel integrated, no discrete NVIDIA card).

### Diagnostic findings (rocminfo on Mary)

`rocminfo` confirmed the AMD GPU (Radeon 890M, `gfx1150`, 16 CUs) is fully detected by ROCm — Agent 2 shows `Device Type: GPU`, `Name: gfx1150`, `Marketing Name: AMD Radeon 890M Graphics`. The ROCk kernel module is loaded.

The current config sets `rocmOverrideGfx = "11.0.0"` which overrides the ISA target to `gfx1100` (RDNA 3). This override is intended for GPUs not yet in ROCm's support list, but `gfx1150` IS natively supported. The override is likely causing Ollama to target the wrong ISA, breaking GPU inference. **Solution: remove the GFX override entirely.**

`rocminfo` itself is only in `hardware.graphics.extraPackages` (not `environment.systemPackages`), so it's not on PATH from the shell — needed for debugging.

## Goals / Non-Goals

**Goals:**
- Create `dpom-ollama` NixOS module with configurable acceleration: `null` (CPU), `"rocm"` (AMD)
- Fix Mary's ROCm GPU acceleration
- Keep the literate workflow: all changes in Config.txt, tangle to .nix files

**Non-Goals:**
- Not adding CUDA support (Bob has Intel integrated graphics only — no discrete GPU)
- Not changing Emacs gptel config (host-agnostic, works either way)
- Not changing port exposure or firewall rules (keep existing per-host differences)
- Not changing model preloading configuration (keep Bob's gemma3:12b)

## Decisions

### 1. Module structure: unified package derivation with acceleration variants

The current `ollama.nix` package override only supports ROCm. We'll extend it to also accept CUDA build inputs, and the module will select the right package + config based on the acceleration option.

The module will provide:
- `dpom-ollama.enable` — enable the module
- `dpom-ollama.acceleration` — one of `null` or `"rocm"` (CPU or AMD GPU)
- `dpom-ollama.rocmGfxOverride` — optional GFX version override string
- `dpom-ollama.loadModels` — list of models to preload

### 2. Package override: ROCm support only (CUDA removed — no NVIDIA GPU on either host)

The package override at `modules/nixos/ollama.nix` already supports `acceleration == "rocm"` with ROCm build inputs. No changes needed:

- `acceleration == "rocm"`: add `rocmPackages.clr`, `rocmPackages.hipblas`, `rocmPackages.rocblas` to buildInputs (existing behavior)
- `acceleration == null`: no extra build inputs (CPU-only, existing behavior)

### 3. Mary ROCm fix approach

rocminfo confirmed the GPU (Radeon 890M, `gfx1150`) is natively supported by ROCm — Agent 2 reports `Device Type: GPU`, native ISA `gfx1150`. The current config sets `rocmOverrideGfx = "11.0.0"` which overrides to `gfx1100`, a wrong ISA target. **This override is the likely root cause of Ollama not using the GPU.**

Fix: **Remove the `rocmOverrideGfx` and `HSA_OVERRIDE_GFX_VERSION` entirely.** The default (no override) lets ROCm use the native `gfx1150` ISA.

Mary will switch from `pkgs.ollama-rocm` to the custom package with `acceleration = "rocm"` for consistency with Bob (both use the same package derivation). Keep:
- `hardware.graphics.extraPackages` with `rocmPackages.clr.icd`, `rocmPackages.clr`, `rocmPackages.rocminfo`
- `LD_LIBRARY_PATH` pointing to ROCm libraries
- Ollama service user with `video` and `render` groups
- Port 11434 open on firewall

Add `rocmPackages.rocminfo` to `environment.systemPackages` so it's available on PATH for future debugging.

### 4. Bob stays CPU-only

Bob has no discrete GPU (`lspci` shows only Intel Comet Lake UHD Graphics). Bob will keep `dpom-ollama.acceleration = null` (CPU mode, the default). The existing config stays functionally the same — just using the new module instead of inline config.

### 5. Inline host config → module conversion

Both `mary/nixos.nix` and `bob/nixos.nix` will replace their inline ollama blocks:

**Mary:**
```nix
dpom-ollama.enable = true;
dpom-ollama.acceleration = "rocm";
```

**Bob:**
```nix
dpom-ollama.enable = true;
dpom-ollama.loadModels = ["gemma3:12b"];
```

## Risks / Trade-offs

- [GPU not detected at runtime] → ROCm/CUDA libraries are in buildInputs but ollama also needs runtime device access. Ensure `video`/`render` groups and `hardware.graphics` are properly configured.
- [Version pin divergence] → Custom package pins Ollama to 0.23.2 while nixpkgs may have newer. Moving both hosts to the custom package ensures consistency but means manual version bumps.
- [Tangle order] → Must edit Config.txt first, tangle to regenerate .nix files. Generated files must be committed alongside Config.txt changes.

## Open Questions

- After removing the GFX override on Mary, does Ollama detect and use the GPU? Verify with `ollama list` and model inference speed.
