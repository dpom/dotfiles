# ollama-acceleration

## Purpose

Manage Ollama GPU acceleration on AMD hardware via ROCm, with CPU fallback for systems without discrete GPUs.

## Requirements

### Requirement: Ollama acceleration mode selection
The system SHALL provide a NixOS module option `dpom-ollama.acceleration` that accepts `null` (CPU-only) or `"rocm"` (AMD GPU).

#### Scenario: Default acceleration is CPU
- **WHEN** `dpom-ollama.enable = true` is set without specifying `dpom-ollama.acceleration`
- **THEN** Ollama SHALL run without GPU acceleration (CPU-only mode)

#### Scenario: ROCm acceleration selected
- **WHEN** `dpom-ollama.acceleration = "rocm"` is set
- **THEN** the Ollama package SHALL be built with ROCm dependencies
- **THEN** `hardware.graphics.extraPackages` SHALL include ROCm ICD and runtime packages
- **THEN** the Ollama service SHALL have `OLLAMA_IGPU_ENABLE=1` set for integrated AMD GPUs
- **THEN** `rocmPackages.rocminfo` SHALL be in `environment.systemPackages` for debugging

#### Scenario: Module follows dpom pattern
- **WHEN** `dpom-ollama.enable = false` (default)
- **THEN** no ollama service SHALL be configured or started

### Requirement: GFX version override for ROCm
The module SHALL provide `dpom-ollama.rocmGfxOverride` as an optional string option to set `HSA_OVERRIDE_GFX_VERSION` and `services.ollama.rocmOverrideGfx`. When unset (default `null`), no override SHALL be applied and ROCm SHALL use the native ISA.

#### Scenario: No GFX override (native ISA)
- **WHEN** `dpom-ollama.rocmGfxOverride` is not set
- **THEN** `HSA_OVERRIDE_GFX_VERSION` SHALL NOT be set
- **THEN** `services.ollama.rocmOverrideGfx` SHALL NOT be set
- **THEN** ROCm SHALL use the GPU's native ISA (e.g., `gfx1150` for Radeon 890M)

#### Scenario: GFX override configured
- **WHEN** `dpom-ollama.rocmGfxOverride = "11.0.0"`
- **THEN** the Ollama service SHALL have the environment variable `HSA_OVERRIDE_GFX_VERSION` set to `"11.0.0"`
- **THEN** `services.ollama.rocmOverrideGfx` SHALL be set to `"11.0.0"`

### Requirement: Model preloading support
The module SHALL pass through `dpom-ollama.loadModels` to `services.ollama.loadModels`.

#### Scenario: Models configured for preloading
- **WHEN** `dpom-ollama.loadModels = ["gemma3:12b"]`
- **THEN** the Ollama service SHALL preload the specified models on startup

### Requirement: Host-specific Ollama configuration
Mary SHALL use ROCm acceleration; Bob SHALL use CPU (no discrete GPU).

#### Scenario: Mary host uses ROCm (native gfx1150)
- **WHEN** deploying to the "mary" host
- **THEN** `dpom-ollama.acceleration` SHALL be set to `"rocm"`
- **THEN** `dpom-ollama.rocmGfxOverride` SHALL NOT be set (native `gfx1150` ISA)
- **THEN** the Ollama service SHALL have `OLLAMA_IGPU_ENABLE=1` for the integrated Radeon 890M
- **THEN** Ollama SHALL be accessible on port 11434 from the local network

#### Scenario: Bob host uses CPU
- **WHEN** deploying to the "bob" host
- **THEN** `dpom-ollama.acceleration` SHALL NOT be set (defaults to `null`, CPU mode)
- **THEN** the `gemma3:12b` model SHALL be preloaded
