## Why

Ollama runs on CPU on Mary despite having an AMD Radeon 890M GPU. The ROCm config exists but GPU acceleration doesn't work due to a wrong GFX ISA override (`gfx1100` for a `gfx1150` GPU). Bob has no discrete GPU (Intel integrated only) and runs CPU-only, which is correct.

## What Changes

- Create a proper `dpom-ollama` NixOS module (`modules/nixos/ollama.nix`) that encapsulates Ollama service configuration
- Remove the incorrect `rocmOverrideGfx = "11.0.0"` on Mary — the `gfx1150` GPU is natively supported by ROCm
- Add `rocmPackages.rocminfo` to `environment.systemPackages` on Mary for debugging
- Replace inline host configs with the new module
- Update `Config.txt` literate source with the new module structure

## Capabilities

### New Capabilities
- `ollama-acceleration`: ROCm GPU acceleration for Ollama on AMD hardware, with CPU fallback

### Modified Capabilities
<!-- No existing specs to modify -->

## Impact

- `modules/nixos/ollama.nix`: Rewritten from a package override to a full NixOS module with `dpom-ollama` options
- `modules/nixos/default.nix`: Add `./ollama.nix` to imports
- `hosts/mary/nixos.nix`: Replace inline ollama config with `dpom-ollama.enable = true` + ROCm options (no GFX override)
- `hosts/bob/nixos.nix`: Replace inline ollama config with `dpom-ollama.enable = true` (CPU-only, no acceleration)
- `Config.txt`: Rewrite ollama Org sections to reflect new module structure
