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
        OLLAMA_NUM_GPU = "35";
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
