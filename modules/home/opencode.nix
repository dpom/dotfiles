{
  config,
  lib,
  pkgs,
  ...
}:
let
  # 1. Definim șablonul de bază fără modelele hardcodate
  opencodeTemplate = pkgs.writeText "opencode-template.json" ''
    {
      "model": "ollama-cloud/gpt-oss:20b",
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

    # Adăugăm comanda în PATH pentru a o putea rula și manual oricând descarci un model nou
    home.packages = [ generateOpencodeConfig ];

    # Rulăm scriptul automat la fiecare aplicare a configurației Home Manager
    home.activation.generateOpencode = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${generateOpencodeConfig}/bin/generate-opencode-config
    '';
  };
}
