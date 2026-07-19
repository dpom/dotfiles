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
      jq --argjson ollama "$OLLAMA_MODELS" --argjson lmstudio "$LMSTUDIO_MODELS" '.provider.ollama.models = $ollama | .provider.lmstudio.models = $lmstudio' "${opencodeTemplate}" > "$CONFIG_FILE"

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
