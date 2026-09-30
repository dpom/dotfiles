{
  config,
  lib,
  pkgs,
  ...
}:
let
  # opencode este pinuit la un release upstream, nu la pkgs.opencode din nixpkgs,
  # ca în ADR-0006. Versiunea și hash-ul se actualizează cu bin/update-opencode.
  opencode = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "opencode";
    version = "1.18.33";
    src = pkgs.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/${pname}-linux-x64.tar.gz";
      hash = "sha256-5UYSMhOuR5CaQmhpKqS5SVDQEa/pysmTh1OiGU8cFtU=";
    };

    # Asset-ul de release conține un singur fișier `opencode`, fără director
    # părinte, deci unpackFile din nixpkgs eșuează cu "unpacker appears to
    # have produced no directories". De aceea despachetul manual.
    unpackPhase = ''
      runHook preUnpack
      tar -xzf "$src"
      runHook postUnpack
    '';

    # NU folosim autoPatchelfHook: pe acest executabil single-file din Bun
    # patchelful automat corupe binarul în tăcăciune (build-ul trece, dar
    # `--version` raportează versiunea runtime-ului Bun, nu pe cea a
    # opencode). Vedem ADR-0007. Repunem interpreterul explicit, cu un
    # singur apel patchelf.
    nativeBuildInputs = [
      pkgs.patchelf
      pkgs.makeWrapper
      pkgs.ripgrep
      pkgs.versionCheckHook
    ];

    installPhase = ''
      runHook preInstall
      install -Dm755 opencode $out/bin/opencode
      patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} $out/bin/opencode
      wrapProgram $out/bin/opencode --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep ]}
      runHook postInstall
    '';

    # Descărcat ca binar, binarul poate ajunge stricat fără niciun semn la
    # build. Verificarea de versiune face ca un astfel de caz să eșueze
    # build-ul în loc să treacă tăcut spre o instalare defectă.
    doInstallCheck = true;
    versionCheckProgramArg = "--version";

    meta = {
      description = "AI coding agent built for the terminal";
      homepage = "https://github.com/anomalyco/opencode";
      license = pkgs.lib.licenses.mit;
      mainProgram = "opencode";
      platforms = [ "x86_64-linux" ];
    };
  };

  # 1. Definim șablonul de bază fără modelele hardcodate
  opencodeTemplate = pkgs.writeText "opencode-template.json" ''
    {
      "model": "opencode/big-pickle",
      "provider": {
        "ollama": {
          "npm": "@ai-sdk/openai-compatible",
          "name": "Ollama (local)",
          "options": {
            "baseURL": "http://localhost:11434/v1"
          },
          "models": {}
        },
        "lmstudio": {
          "npm": "@ai-sdk/openai-compatible",
          "name": "LM Studio (local)",
          "options": {
            "baseURL": "http://localhost:1234/v1"
          },
          "models": {}
        },
        "ollama-cloud": {
          "npm": "@ai-sdk/openai-compatible",
          "name": "Ollama Cloud",
          "options": {
            "baseURL": "https://ollama.com/v1"
          },
          "models": {
            "gpt-oss:20b": {
              "name": "GPT-OSS 20B",
              "limit": { "context": 131072, "output": 32768 }
            },
            "gpt-oss:120b": {
              "name": "GPT-OSS 120B",
              "limit": { "context": 131072, "output": 131072 }
            },
            "nemotron-3-nano:30b": {
              "name": "Nemotron 3 Nano 30B",
              "limit": { "context": 262144, "output": 131072 }
            },
            "nemotron-3-super": {
              "name": "Nemotron 3 Super",
              "limit": { "context": 262144, "output": 262144 }
            },
            "gemma4:31b": {
              "name": "Gemma 4 31B",
              "limit": { "context": 262144, "output": 131072 }
            },
            "qwen3.5:397b": {
              "name": "Qwen 3.5 397B",
              "limit": { "context": 262144, "output": 262144 }
            },
            "deepseek-v4-flash:0731": {
              "name": "DeepSeek V4 Flash 0731",
              "limit": { "context": 1000000, "output": 384000 }
            },
            "deepseek-v4-flash:preview": {
              "name": "DeepSeek V4 Flash Preview",
              "limit": { "context": 1000000, "output": 384000 }
            },
            "minimax-m2.7": {
              "name": "MiniMax M2.7",
              "limit": { "context": 204800, "output": 131072 }
            }
          }
        }
      }
    }
  '';

  # 2. Creăm scriptul care interoghează Ollama și generează configurația finală
  generateOpencodeConfig = pkgs.writeShellApplication {
    name = "generate-opencode-config";
    runtimeInputs = with pkgs; [ curl jq ];
    text = ''
      CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
      CONFIG_FILE="$CONFIG_DIR/opencode.json"

      mkdir -p "$CONFIG_DIR"

      echo "Querying Ollama for local models..."
      if curl -s -f http://localhost:11434/api/tags > /dev/null; then
          OLLAMA_MODELS=$(curl -s http://localhost:11434/api/tags | jq -c '
            reduce .models[] as $m ( {}; .[$m.name] = { "name": $m.name, "limit": { "context": 65536, "output": 32768 } } )
          ')
          echo "Found Ollama models."
      else
          echo "Warning: Ollama is not running or unreachable. Using empty model list."
          OLLAMA_MODELS="{}"
      fi

      echo "Querying LM Studio for local models..."
      if curl -s -f http://localhost:1234/v1/models > /dev/null; then
          LMSTUDIO_MODELS=$(curl -s http://localhost:1234/v1/models | jq -c '
            reduce .data[] as $m ( {}; .[$m.id] = { "name": $m.id, "limit": { "context": 65536, "output": 32768 } } )
          ')
          echo "Found LM Studio models."
      else
          echo "Warning: LM Studio is not running or unreachable. Using empty model list."
          LMSTUDIO_MODELS="{}"
      fi

      echo "Generating $CONFIG_FILE..."
      jq --argjson ollama "$OLLAMA_MODELS" --argjson lmstudio "$LMSTUDIO_MODELS" --arg ollamacloudkey "$(cat ${config.sops.secrets.ollama_cloud_api_key.path})" '.provider.ollama.models = $ollama | .provider.lmstudio.models = $lmstudio | .provider["ollama-cloud"].options.apiKey = $ollamacloudkey' "${opencodeTemplate}" > "$CONFIG_FILE"

      echo "Done! Configuration saved to $CONFIG_FILE."
    '';
  };

in
{
  options = {
    dpom-opencode.enable = lib.mkEnableOption "Add opencode agent";
  };

  config = lib.mkIf config.dpom-opencode.enable {
    # Păstrăm activarea programului (dacă instalează pachetul), dar eliminăm `programs.opencode.settings`
    programs.opencode.enable = true;

    # Installăm pin-ul nostru, nu pkgs.opencode din nixpkgs (ADR-0006).
    programs.opencode.package = opencode;

    # Adăugăm comanda în PATH pentru a o putea rula și manual oricând descarci un model nou
    home.packages = [ generateOpencodeConfig ];

    # Rulăm scriptul automat la fiecare aplicare a configurației Home Manager
    home.activation.generateOpencode = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${generateOpencodeConfig}/bin/generate-opencode-config
    '';
  };
}
