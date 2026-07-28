{ config, pkgs, lib, ... }:
let
  version = "17.1.7";
  oh-my-pi = pkgs.stdenv.mkDerivation {
    pname = "oh-my-pi";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
      hash = "sha256-M74CMt6P/01UIFjWZu4VzxVKZgCSJX1L+z/qi8f59uA=";
    };
    dontUnpack = true;
    dontStrip = true;
    nativeBuildInputs = with pkgs; [ makeBinaryWrapper ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp $src $out/bin/omp
      chmod +x $out/bin/omp
      runHook postInstall
    '';
    postFixup = ''
      wrapProgram $out/bin/omp \
        --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep pkgs.fd ]}
    '';
    meta = {
      description = "AI coding agent for the terminal - fork of Pi with enhanced capabilities";
      homepage = "https://omp.sh";
      license = lib.licenses.mit;
      mainProgram = "omp";
      platforms = [ "x86_64-linux" ];
    };
  };

  generateOmpConfig = pkgs.writeShellApplication {
    name = "generate-omp-config";
    runtimeInputs = with pkgs; [ curl ];
    text = ''
      OMP_AGENT_DIR="$HOME/.omp/agent"
      mkdir -p "$OMP_AGENT_DIR"

      MODELS_FILE="$OMP_AGENT_DIR/models.yml"

      echo "Querying Ollama for local models..."
      OLLAMA_MODELS=""
      if curl -s -f http://localhost:11434/api/tags > /dev/null 2>&1; then
        OLLAMA_MODELS=$(curl -s http://localhost:11434/api/tags | ${pkgs.jq}/bin/jq -r '
          [.models[] | {
            id: .name,
            name: ((.name | split(":")[0] | gsub("-"; " ")) + " (Local)"),
            contextWindow: 65536,
            maxTokens: 32768
          }] | .[] | "    - id: \"\(.id)\"\n      name: \"\(.name)\"\n      contextWindow: \(.contextWindow)\n      maxTokens: \(.maxTokens)"
        ')
        if [ -n "$OLLAMA_MODELS" ]; then
          OLLAMA_MODELS=$(printf "\n%s" "$OLLAMA_MODELS")
        fi
      else
        echo "Warning: Ollama is not running."
      fi

      echo "Querying LM Studio for local models..."
      LMSTUDIO_MODELS=""
      if curl -s -f http://localhost:1234/v1/models > /dev/null 2>&1; then
        LMSTUDIO_MODELS=$(curl -s http://localhost:1234/v1/models | ${pkgs.jq}/bin/jq -r '
          [.data[] | {
            id: .id,
            name: ((.id | split(":")[0] | gsub("-"; " ")) + " (Local)"),
            contextWindow: 65536,
            maxTokens: 32768
          }] | .[] | "    - id: \"\(.id)\"\n      name: \"\(.name)\"\n      contextWindow: \(.contextWindow)\n      maxTokens: \(.maxTokens)"
        ')
        if [ -n "$LMSTUDIO_MODELS" ]; then
          LMSTUDIO_MODELS=$(printf "\n%s" "$LMSTUDIO_MODELS")
        fi
      else
        echo "Warning: LM Studio is not running."
      fi

      echo "Generating $$MODELS_FILE..."
      cat > "$MODELS_FILE" <<YAML
providers:
  ollama:
    baseUrl: http://localhost:11434/v1
    api: openai-completions
    apiKey: ollama
    models:$OLLAMA_MODELS

  lmstudio:
    baseUrl: http://localhost:1234/v1
    api: openai-completions
    apiKey: lm-studio
    models:$LMSTUDIO_MODELS

  anthropic:
    api: anthropic-messages
    models: []

  openai:
    api: openai-completions
    models: []
YAML
      echo "Done! Configuration saved to $$MODELS_FILE."
    '';
  };

in
{
  options = {
    dpom-oh-my-pi.enable = lib.mkEnableOption "Add oh-my-pi coding agent (omp)";
  };
  config = lib.mkIf config.dpom-oh-my-pi.enable {
    home.packages = [ oh-my-pi generateOmpConfig ];

    home.activation.generateOmpConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${generateOmpConfig}/bin/generate-omp-config
    '';

    home.activation.generateOmpCompletions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Bash completions
      BASH_MARKER="# oh-my-pi completions"
      if [ -f "$HOME/.bashrc" ] && ! grep -qF "$BASH_MARKER" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "$BASH_MARKER" >> "$HOME/.bashrc"
        echo 'eval "$(omp completions bash)"' >> "$HOME/.bashrc"
      fi

      # Zsh completions
      ZSH_MARKER="# oh-my-pi completions"
      if [ -f "$HOME/.zshrc" ] && ! grep -qF "$ZSH_MARKER" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "$ZSH_MARKER" >> "$HOME/.zshrc"
        echo 'eval "$(omp completions zsh)"' >> "$HOME/.zshrc"
      fi

      # Fish completions
      mkdir -p "$HOME/.config/fish/completions"
      omp completions fish > "$HOME/.config/fish/completions/omp.fish"
    '';
  };
}
