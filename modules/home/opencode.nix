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
          # Transformă array-ul de modele de la Ollama în obiectul așteptat de opencode
          # Alocă automat o limită implicită de context pentru fiecare model găsit
          MODELS_JSON=$(curl -s http://localhost:11434/api/tags | jq -c '
            reduce .models[] as $m ( {}; .[$m.name] = { "name": $m.name, "limit": { "context": 65536, "output": 32768 } } )
          ')
          echo "Found models, updating config."
      else
          echo "Warning: Ollama is not running or unreachable. Using empty model list."
          MODELS_JSON="{}"
      fi

      echo "Generating $CONFIG_FILE..."
      # Injectează obiectul generat în șablonul de bază
      jq --argjson models "$MODELS_JSON" '.provider.ollama.models = $models' "${opencodeTemplate}" > "$CONFIG_FILE"

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
