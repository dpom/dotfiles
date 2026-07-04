{ config, pkgs, lib, ... }:
let
  pi-acp = pkgs.buildNpmPackage rec {
    pname = "pi-acp";
    version = "0.0.31";
    src = pkgs.fetchFromGitHub {
      owner = "svkozak";
      repo = "pi-acp";
      rev = "v${version}";
      hash = "sha256-bM3V/3fxkY2Ib+OyfT82StIIRSLXGDuYUbt1CZKpTuo=";
    };
    npmDepsHash = "sha256-qN+b/tMbnJLkWjotl3XrA0nfZ3KT/mT6gM+n3Qiz8Wk=";
    dontStrip = true;
    nativeBuildInputs = with pkgs; [ makeBinaryWrapper ];
    buildInputs = with pkgs; [ nodejs_24 ];
    env.NIX_MAIN_PROGRAM = "pi-acp";
    env.NIX_NPM_FETCHER_VERSION = "1";
    meta.mainProgram = "pi-acp";
  };

  pi-coding-agent = pkgs.buildNpmPackage rec {
    pname = "pi-coding-agent";
    version = "0.80.3";
    src = pkgs.fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      rev = "v${version}";
      hash = "sha256-wQTrWKsb2HCGwzSAFEk8NWSDpqxSY/lv1/R6ghcmbaA=";
    };
    npmDepsHash = "sha256-geh8LH88OZybFXkR/jDeTdew6TNMdFM6jhCSYKn//dU=";
    npmRebuildFlags = [ "--ignore-scripts" ];
    npmBuildScript = "build";
    npmWorkspace = "packages/coding-agent";
    buildPhase = ''
      runHook preBuild
      npx tsgo -p packages/ai/tsconfig.build.json
      npx tsgo -p packages/tui/tsconfig.build.json
      npx tsgo -p packages/agent/tsconfig.build.json
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
      for ws in @earendil-works/pi-ai:packages/ai \
                @earendil-works/pi-agent-core:packages/agent \
                @earendil-works/pi-tui:packages/tui; do
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
        MODELS_JSON=$(curl -s http://localhost:11434/api/tags | jq -c '
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
        MODELS_JSON="[]"
      fi

      echo "Generating $$PI_AGENT_DIR/models.json..."
      jq --argjson models "$MODELS_JSON" '.providers.ollama.models = $models' "${piConfigTemplate}" > "$PI_AGENT_DIR/models.json"
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
