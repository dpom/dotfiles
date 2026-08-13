{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dpom-ollama;
  version = "0.32.9";

  # Prebuilt binaries from the ollama/ollama GitHub release.
  # Kept up to date with bin/update-ollama.
  # The base asset contains the binary plus CPU libraries; the -rocm
  # asset only carries the ROCm libraries to layer on top of the base.
  mkOllamaBase = { asset, hash }: pkgs.stdenv.mkDerivation {
    pname = "ollama";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/ollama/ollama/releases/download/v${version}/${asset}";
      inherit hash;
    };
    dontUnpack = true;
    dontStrip = true;
    nativeBuildInputs = [ pkgs.zstd ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      tar --use-compress-program=zstd -xf $src -C $out
      chmod +x $out/bin/ollama
      runHook postInstall
    '';
    meta = {
      mainProgram = "ollama";
      description = "Get up and running with large language models locally";
      homepage = "https://ollama.com";
      license = lib.licenses.mit;
      platforms = [ "x86_64-linux" ];
    };
  };

  ollama-cpu = mkOllamaBase {
    asset = "ollama-linux-amd64.tar.zst";
    hash = "sha256-XXR6QzafYeOPILWjn8xckGR+VizcYeLlYDTxxbET1UA=";
  };

  # ROCm libraries only; layered over the base binary below.
  ollama-rocm-libs = pkgs.stdenv.mkDerivation {
    pname = "ollama-rocm-libs";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64-rocm.tar.zst";
      hash = "sha256-q5PJMd8+pXCCf1f6dSs76nu8lhr3FBL8DUza9cSKNWo=";
    };
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.zstd ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      tar --use-compress-program=zstd -xf $src -C $out
      runHook postInstall
    '';
  };

  ollama-rocm = ollama-cpu.overrideAttrs (old: {
    pname = "ollama-rocm";
    installPhase = old.installPhase + ''
      cp -r ${ollama-rocm-libs}/lib/ollama/. $out/lib/ollama/
    '';
  });
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
      package = if cfg.acceleration == "rocm" then ollama-rocm else ollama-cpu;
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
