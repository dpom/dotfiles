{
  config,
  lib,
  pkgs,
  ...
}:
let
  host = config.networking.hostName;
  isMary = host == "mary";
  isBob = host == "bob";

  apiBase = if isMary then "http://localhost:8000/v1" else "http://localhost:11434/v1";
  providerName = if isMary then "vLLM (local)" else "Ollama (local)";
  providerId = if isMary then "vllm" else "ollama";

  opencodeTemplate = pkgs.writeText "opencode-template.json" (builtins.toJSON {
    model = if isMary then "local/model" else "ollama/qwen3.6:27b";
    provider = {
      "${providerId}" = {
        npm = "@ai-sdk/openai-compatible";
        name = providerName;
        options = {
          baseURL = apiBase;
        };
        models = {};
      };
    };
  });

  generateOpencodeConfig = pkgs.writeShellApplication {
    name = "generate-opencode-config";
    runtimeInputs = with pkgs; [ curl jq ];
    text = ''
      CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
      CONFIG_FILE="$CONFIG_DIR/opencode.json"
      PROVIDER="${providerId}"
      API_BASE="${apiBase}"

      mkdir -p "$CONFIG_DIR"

      if [ "$PROVIDER" = "ollama" ]; then
        echo "Querying Ollama for local models..."
        if curl -s -f "http://localhost:11434/api/tags" > /dev/null; then
          MODELS_JSON=$(curl -s "http://localhost:11434/api/tags" | jq -c '
            reduce .models[] as $m ( {}; .[$m.name] = { "name": $m.name, "limit": { "context": 65536, "output": 32768 } } )
          ')
          echo "Found models, updating config."
        else
          echo "Warning: Ollama is not running or unreachable. Using empty model list."
          MODELS_JSON="{}"
        fi
      else
        echo "Querying vLLM for available models..."
        if curl -s -f "$API_BASE/models" > /dev/null; then
          MODELS_JSON=$(curl -s "$API_BASE/models" | jq -c '
            reduce .data[] as $m ( {}; .[$m.id] = { "name": $m.id, "limit": { "context": 65536, "output": 32768 } } )
          ')
          echo "Found models, updating config."
        else
          echo "Warning: vLLM is not running or unreachable. Using empty model list."
          MODELS_JSON="{}"
        fi
      fi

      echo "Generating $CONFIG_FILE..."
      FIRST_MODEL=$(echo "$MODELS_JSON" | jq -r 'keys[0] // ""')
      jq --arg model "$FIRST_MODEL" --argjson models "$MODELS_JSON" '
        .model = (if $model != "" then $model else .model end)
        | .provider."'"$PROVIDER"'".models = $models
      ' "${opencodeTemplate}" > "$CONFIG_FILE"

      echo "Done! Configuration saved to $CONFIG_FILE."
    '';
  };

in
{
  options = {
    dpom-opencode.enable = lib.mkEnableOption "Add opencode agent";
  };

  config = lib.mkIf config.dpom-opencode.enable {
    programs.opencode.enable = true;

    home.packages = [ generateOpencodeConfig ];

    home.activation.generateOpencode = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${generateOpencodeConfig}/bin/generate-opencode-config
    '';
  };
}
