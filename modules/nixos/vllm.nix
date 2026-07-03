{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dpom-vllm;
  vllmImage = "vllm/vllm-openai-rocm:nightly";
in {
  options.dpom-vllm = {
    enable = lib.mkEnableOption "vLLM container with GPU acceleration support";
    acceleration = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "rocm" ]);
      default = null;
      description = "GPU acceleration backend for vLLM (null = CPU, rocm = AMD GPU)";
    };
    rocmGfxOverride = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional GFX version override for ROCm (e.g. 11.0.0).";
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
    dpom-podman.enable = true;
    sops.secrets.hf_token = {};

    systemd.tmpfiles.rules = [
      "d /var/lib/vllm 0755 root root -"
    ];

    virtualisation.oci-containers = {
      backend = "podman";
      containers.vllm = {
        image = vllmImage;
        autoStart = true;
        ports = [ "${toString cfg.port}:8000" ];
        volumes = [ "/var/lib/vllm:/root/.cache/huggingface" ];
        extraOptions =
          [ "--pull=newer" ]
          ++ lib.optionals (cfg.acceleration == "rocm") [
            "--device=/dev/kfd"
            "--device=/dev/dri"
            "--group-add=video"
          ]
          ++ [ "--env-file" config.sops.secrets.hf_token.path ];
        environment = {
          HUGGING_FACE_HUB_CACHE = "/root/.cache/huggingface";
          HF_XET_HIGH_PERFORMANCE = "1";
        } // lib.optionalAttrs (cfg.acceleration == "rocm" && cfg.rocmGfxOverride != null) {
          HSA_OVERRIDE_GFX_VERSION = cfg.rocmGfxOverride;
        };
        cmd = lib.optionals (cfg.model != "") ([
          "--model" cfg.model
        ]) ++ [
          "--port" "8000"
          "--host" "0.0.0.0"
        ] ++ cfg.extraArgs;
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

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
