{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dpom-ollama;
in {
  options.dpom-ollama = {
    enable = lib.mkEnableOption "Ollama service with GPU acceleration support";
    acceleration = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "rocm" ]);
      default = null;
      description = "GPU acceleration backend for Ollama (null = CPU, rocm = AMD GPU)";
    };
    rocmGfxOverride = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional GFX version override for ROCm (e.g. 11.0.0). Leave null for native ISA.";
    };
    loadModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of models to preload on startup";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama.override {
        acceleration = if cfg.acceleration == "rocm" then "rocm" else null;
      };
      inherit (cfg) loadModels;
      rocmOverrideGfx = cfg.rocmGfxOverride;
      environmentVariables = lib.mkIf (cfg.acceleration == "rocm") {
        OLLAMA_IGPU_ENABLE = "1";
        # Încarcă doar 40 de straturi pe iGPU, restul pe CPU.
        # OLLAMA_NUM_GPU = "35";
        # KV Cache Quantization: Quantizes the context cache to 8-bit, allowing roughly 2x longer context within the same VRAM limit.
        OLLAMA_KV_CACHE_TYPE = "q8_0";
        # Flash Attention: Reduces memory overhead for the attention mechanism.
        OLLAMA_FLASH_ATTENTION = "1";
        # Context
        OLLAMA_CONTEXT_LENGTH = "64000";
      };
    };

    hardware.graphics = lib.mkIf (cfg.acceleration == "rocm") {
      enable = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
        rocmPackages.clr
        rocmPackages.rocminfo
      ];
    };

    environment.systemPackages = lib.mkIf (cfg.acceleration == "rocm") (with pkgs; [
      rocmPackages.rocminfo
    ]);
  };
}
