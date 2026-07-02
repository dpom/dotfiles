{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dpom-vllm;
in {
  options.dpom-vllm = {
    enable = lib.mkEnableOption "vLLM inference server with GPU acceleration support";
    acceleration = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "rocm" ]);
      default = null;
      description = "GPU acceleration backend for vLLM (null = CPU, rocm = AMD GPU)";
    };
    rocmGfxOverride = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional GFX version override for ROCm (e.g. 11.0.0). Leave null for native ISA.";
    };
    model = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Model to serve (e.g. Qwen/Qwen2.5-14B-Instruct-GPTQ-Int4)";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Port for the OpenAI-compatible API";
    };
    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "--gpu-memory-utilization" "0.90" ];
      description = "Additional CLI arguments passed to vllm serve";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.permittedInsecurePackages = [
      "python3.13-vllm-0.16.0"
    ];

    users.users.vllm = {
      isSystemUser = true;
      group = "vllm";
      home = "/var/lib/vllm";
      createHome = true;
    };
    users.groups.vllm = {};

    systemd.tmpfiles.rules = [
      "d /var/lib/vllm 0755 vllm vllm -"
    ];

    systemd.services.vllm = {
      description = "vLLM LLM Inference Server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "vllm";
        Group = "vllm";
        ExecStart = "${lib.getExe' pkgs.vllm "vllm"} serve ${cfg.model} --port ${toString cfg.port} --host 127.0.0.1 ${lib.escapeShellArgs cfg.extraArgs}";
        Restart = "on-failure";
        RestartSec = "5";
        Environment = [
          "HF_HOME=/var/lib/vllm"
          "XDG_CACHE_HOME=/var/lib/vllm"
        ];
      } // lib.optionalAttrs (cfg.acceleration == "rocm" && cfg.rocmGfxOverride != null) {
        Environment = (builtins.filter (e: !lib.hasPrefix "HSA_OVERRIDE_GFX_VERSION=" e) [
          "HF_HOME=/var/lib/vllm"
          "XDG_CACHE_HOME=/var/lib/vllm"
        ]) ++ [ "HSA_OVERRIDE_GFX_VERSION=${cfg.rocmGfxOverride}" ];
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
