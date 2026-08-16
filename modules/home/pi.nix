{ config, pkgs, lib, ... }:
let
  pi-acp = pkgs.buildNpmPackage rec {
    pname = "pi-acp";
    version = "0.0.33";
    src = pkgs.fetchFromGitHub {
      owner = "svkozak";
      repo = "pi-acp";
      rev = "v${version}";
      hash = "sha256-fENOOdooi4XbIDjcr02q8qzUCzdo2IW/Bca43SawZ44=";
    };
    npmDepsHash = "sha256-/fX79XucKojL/6gZbK5eizEfrXso8rlTgiHfJffmDuY=";
    dontStrip = true;
    nativeBuildInputs = with pkgs; [ makeBinaryWrapper ];
    buildInputs = with pkgs; [ nodejs_24 ];
    env.NIX_MAIN_PROGRAM = "pi-acp";
    env.NIX_NPM_FETCHER_VERSION = "1";
    meta.mainProgram = "pi-acp";
  };

  pi-coding-agent = pkgs.buildNpmPackage rec {
    pname = "pi-coding-agent";
    version = "0.84.2";
    src = pkgs.fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      rev = "v${version}";
      hash = "sha256-d29ft9otYxdHRWYIAX8KMHPpppToX9ME5LbPb1rPcYo=";
    };
    modelData = ./pi-model-data/${version};
    postPatch = ''
      cp -r ${modelData}/. packages/ai/src/providers/data/
    '';
    npmDepsHash = "sha256-6J5Efe+6ptCuR3VZojwYPZO8BBnnZsOQ4OAeB64uYOY=";
    npmRebuildFlags = [ "--ignore-scripts" ];
    npmBuildScript = "build";
    npmWorkspace = "packages/coding-agent";
    buildPhase = ''
      runHook preBuild
      node packages/ai/scripts/check-model-data.ts
      npx tsgo -p packages/telemetry/tsconfig.build.json
      npx tsgo -p packages/ai/tsconfig.build.json
      cp -r packages/ai/src/providers/data packages/ai/dist/providers/data
      npx tsgo -p packages/tui/tsconfig.build.json
      npx tsgo -p packages/agent/tsconfig.build.json
      npx tsgo -p packages/protocol/tsconfig.build.json
      npx tsgo -p packages/client/tsconfig.build.json
      npm run build --workspace=packages/coding-agent
      runHook postBuild
    '';
    dontStrip = true;
    nativeBuildInputs = with pkgs; [
      makeBinaryWrapper
      python3
      versionCheckHook
    ];
    buildInputs = with pkgs; [
      nodejs_24
    ];
    env.NIX_MAIN_PROGRAM = "pi";
    env.NIX_NPM_FETCHER_VERSION = "1";
    versionCheckProgram = "${placeholder "out"}/bin/pi";
    versionCheckProgramArg = "--version";
    postInstall = ''
      local nm="$out/lib/node_modules/pi-monorepo/node_modules"
      for ws in @earendil-works/pi-telemetry:packages/telemetry \
                @earendil-works/pi-protocol:packages/protocol \
                @earendil-works/pi-ai:packages/ai \
                @earendil-works/pi-agent-core:packages/agent \
                @earendil-works/pi-tui:packages/tui \
                @earendil-works/pi-client:packages/client; do
        IFS=: read -r pkg src <<< "$ws"
        rm "$nm/$pkg"
        cp -r "$src" "$nm/$pkg"
      done
      find "$nm" -type l -lname '*/packages/*' -delete
      find "$nm/.bin" -xtype l -delete
    '';
    postFixup = ''
      wrapProgram $out/bin/pi \
        --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep pkgs.fd ]}
    '';
    meta = {
      mainProgram = "pi";
    };
  };

  piConfigTemplate = pkgs.writeText "pi-models-template.json" ''
    {
      "providers": {
        "ollama": {
          "baseUrl": "http://localhost:11434/v1",
          "api": "openai-completions",
          "apiKey": "ollama",
          "compat": {
            "supportsDeveloperRole": false,
            "supportsReasoningEffort": false
          }
        },
        "lmstudio": {
          "baseUrl": "http://localhost:1234/v1",
          "api": "openai-completions",
          "apiKey": "lm-studio",
          "compat": {
            "supportsDeveloperRole": true,
            "supportsReasoningEffort": false
          }
        },
        "ollama-cloud": {
          "baseUrl": "https://ollama.com/v1",
          "api": "openai-completions",
          "models": [
            { "id": "gpt-oss:20b", "name": "GPT-OSS 20B", "input": ["text"], "contextWindow": 131072, "maxTokens": 32768 },
            { "id": "gpt-oss:120b", "name": "GPT-OSS 120B", "input": ["text"], "contextWindow": 131072, "maxTokens": 131072 },
            { "id": "nemotron-3-nano:30b", "name": "Nemotron 3 Nano 30B", "input": ["text"], "contextWindow": 262144, "maxTokens": 131072 },
            { "id": "nemotron-3-super", "name": "Nemotron 3 Super", "input": ["text"], "contextWindow": 262144, "maxTokens": 262144 },
            { "id": "gemma4:31b", "name": "Gemma 4 31B", "input": ["text"], "contextWindow": 262144, "maxTokens": 131072 },
            { "id": "qwen3.5:397b", "name": "Qwen 3.5 397B", "input": ["text"], "contextWindow": 262144, "maxTokens": 262144 },
            { "id": "deepseek-v4-flash:0731", "name": "DeepSeek V4 Flash 0731", "input": ["text"], "contextWindow": 1000000, "maxTokens": 384000 },
            { "id": "deepseek-v4-flash:preview", "name": "DeepSeek V4 Flash Preview", "input": ["text"], "contextWindow": 1000000, "maxTokens": 384000 },
            { "id": "minimax-m2.7", "name": "MiniMax M2.7", "input": ["text"], "contextWindow": 204800, "maxTokens": 131072 }
          ]
        }
      }
    }
  '';

  generatePiConfig = pkgs.writeShellApplication {
    name = "generate-pi-config";
    runtimeInputs = with pkgs; [ curl jq ];
    text = ''
      PI_AGENT_DIR="$HOME/.pi/agent"
      mkdir -p "$PI_AGENT_DIR"

      echo "Querying Ollama for local models..."
      if curl -s -f http://localhost:11434/api/tags > /dev/null; then
        OLLAMA_MODELS=$(curl -s http://localhost:11434/api/tags | jq -c '
          [.models[] | {
            id: .name,
            name: (.name | split(":")[0] | gsub("-"; " ") | split(" ") | map((.[0:1] | ascii_upcase) + .[1:]) | join(" ")) + " (Local)",
            input: ["text"],
            contextWindow: 65536,
            maxTokens: 32768
          }]
        ')
      else
        echo "Warning: Ollama is not running. Using empty model list."
        OLLAMA_MODELS="[]"
      fi

      echo "Querying LM Studio for local models..."
      if curl -s -f http://localhost:1234/v1/models > /dev/null; then
        LMSTUDIO_MODELS=$(curl -s http://localhost:1234/v1/models | jq -c '
          [.data[] | {
            id: .id,
            name: (.id | split(":")[0] | gsub("-"; " ") | split(" ") | map((.[0:1] | ascii_upcase) + .[1:]) | join(" ")) + " (Local)",
            input: ["text"],
            contextWindow: 65536,
            maxTokens: 32768
          }]
        ')
      else
        echo "Warning: LM Studio is not running. Using empty model list."
        LMSTUDIO_MODELS="[]"
      fi

      echo "Generating $$PI_AGENT_DIR/models.json..."
      jq --argjson ollama "$OLLAMA_MODELS" --argjson lmstudio "$LMSTUDIO_MODELS" --arg ollamacloudkey "$(cat ${config.sops.secrets.ollama_cloud_api_key.path})" '.providers.ollama.models = $ollama | .providers.lmstudio.models = $lmstudio | .providers["ollama-cloud"].apiKey = $ollamacloudkey' "${piConfigTemplate}" > "$PI_AGENT_DIR/models.json"
      echo "Done! Configuration saved to $PI_AGENT_DIR/models.json."
    '';
  };
in
{
  options = {
    dpom-pi.enable = lib.mkEnableOption "Add pi coding agent";
  };
  config = lib.mkIf config.dpom-pi.enable {
    home.packages = [ pi-coding-agent pi-acp generatePiConfig ];
    home.activation.generatePiConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${generatePiConfig}/bin/generate-pi-config
    '';
  };
}
