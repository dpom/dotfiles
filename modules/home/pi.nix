{ config, pkgs, lib, ... }:
let
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
in
{
  options = {
    dpom-pi.enable = lib.mkEnableOption "Add pi coding agent";
  };
  config = lib.mkIf config.dpom-pi.enable {
    home.packages = [ pi-coding-agent ];
    home.file.".pi/agent/models.json" = {
      text = builtins.toJSON {
        providers = {
          ollama = {
            baseUrl = "http://localhost:11434/v1";
            api = "openai-completions";
            apiKey = "ollama";
            compat = {
              supportsDeveloperRole = false;
              supportsReasoningEffort = false;
            };
            models = [
              {
                id = "gemma4:e4b";
                name = "Gemma 4 (Local)";
                reasoning = true;
                input = [ "text" "image" ];
                contextWindow = 131072;
                maxTokens = 8192;
              }
              {
                id = "qwen2.5-coder:7b";
                name = "Qwen 2.5 Coder 7B (Local)";
                reasoning = true;
                input = [ "text" ];
                contextWindow = 32768;
                maxTokens = 8192;
              }
              {
                id = "qwen3.5:9b";
                name = "Qwen 3.5 9B (Local)";
                reasoning = true;
                input = [ "text" ];
                contextWindow = 131072;
                maxTokens = 8192;
              }
              {
                id = "llama3.1:8b";
                name = "Llama 3.1 8B (Local)";
                input = [ "text" ];
                contextWindow = 128000;
                maxTokens = 8192;
              }
              {
                id = "llama3.2:3b";
                name = "Llama 3.2 3B (Local)";
                input = [ "text" ];
                contextWindow = 128000;
                maxTokens = 8192;
              }
              {
                id = "TranslateGemma:4b";
                name = "Translate Gemma 4B (Local)";
                input = [ "text" ];
                contextWindow = 8192;
                maxTokens = 4096;
              }
            ];
          };
        };
      };
    };
  };
}
