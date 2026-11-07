{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dpom-llama-cpp;
in {
  options.dpom-llama-cpp = {
    enable = lib.mkEnableOption "llama.cpp OpenAI-compatible server";
    acceleration = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "rocm" ]);
      default = null;
      description = "GPU acceleration backend for llama.cpp (null = CPU, rocm = AMD GPU)";
    };
    modelAlias = lib.mkOption {
      type = lib.types.str;
      default = "qwen3-coder-30b-a3b-instruct";
      description = "Model alias exposed by the server and used by clients";
    };
    hfRepo = lib.mkOption {
      type = lib.types.str;
      default = "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF";
      description = "Hugging Face repository that provides the GGUF model";
    };
    hfFile = lib.mkOption {
      type = lib.types.str;
      default = "Qwen3-Coder-30B-A3B-Instruct-UD-Q4_K_XL.gguf";
      description = "GGUF file to download from the Hugging Face repository";
    };
    contextLength = lib.mkOption {
      type = lib.types.ints.positive;
      default = 65536;
      description = "Context size in tokens";
    };
    parallel = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
      description = "Number of inference slots";
    };
    maxModels = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
      description = "Maximum number of models the server may load";
    };
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address the server listens on";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port the server listens on";
    };
    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional llama-server flags";
    };
  };

  config = lib.mkIf cfg.enable {
    services.llama-cpp = {
      enable = true;
      package =
        if cfg.acceleration == "rocm" then
          pkgs.llama-cpp.override {
            rocmSupport = true;
            rocmPackages = pkgs.rocmPackages;
            rocmGpuTargets = [ "gfx1150" ];
          }
        else
          pkgs.llama-cpp;
      inherit (cfg) host port;
      openFirewall = false;
      modelsPreset = {
        "Qwen3-Coder-30B-A3B-Instruct" = {
          hf-repo = cfg.hfRepo;
          hf-file = cfg.hfFile;
          alias = cfg.modelAlias;
          jinja = "on";
          temp = "0.7";
          top-p = "0.8";
          top-k = "20";
          min-p = "0.0";
          repeat-penalty = "1.05";
        };
      };
      extraFlags = [
        "--ctx-size"
        (toString cfg.contextLength)
        "--parallel"
        (toString cfg.parallel)
        "--models-max"
        (toString cfg.maxModels)
        "--n-gpu-layers"
        "999"
        "--cache-type-k"
        "q8_0"
        "--cache-type-v"
        "q8_0"
        "--no-webui"
      ] ++ cfg.extraFlags;
    };

    systemd.services.llama-cpp.serviceConfig.SupplementaryGroups =
      lib.mkIf (cfg.acceleration == "rocm") [ "render" ];

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
