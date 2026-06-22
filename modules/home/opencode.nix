{
  config,
  lib,
  ...
}:
{
  options = {
    dpom-opencode.enable = lib.mkEnableOption "Add opencode agent";
  };
  config = lib.mkIf config.dpom-opencode.enable {
    programs.opencode.enable = true;

    programs.opencode.settings = {
      model = "ollama/qwen3-coder:30b";
      provider = {
        ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (local)";
          options = {
            baseURL = "http://localhost:11434/v1";
          };
          models = {
            "qwen3-coder:30b" = {
              name = "qwen3-coder:30b";
              limit = { context = 65536; output = 32768; };
            };
            "qwen3.6:27b" = {
              name = "qwen3.6:27b";
              limit = { context = 65536; output = 32768; };
            };
            "gemma4:26b" = {
              name = "gemma4:26b";
              limit = { context = 32768; output = 16384; };
            };
            "llama4:maverick" = {
              name = "llama4:maverick";
              limit = { context = 65536; output = 32768; };
            };
            "gemma4:latest" = {
              name = "gemma4:latest";
              limit = { context = 32768; output = 16384; };
            };
            "deepseek-coder-v2:latest" = {
              name = "deepseek-coder-v2:latest";
              limit = { context = 65536; output = 32768; };
            };
            "codestral:latest" = {
              name = "codestral:latest";
              limit = { context = 32768; output = 16384; };
            };
            "deepseek-r1:latest" = {
              name = "deepseek-r1:latest";
              limit = { context = 32768; output = 16384; };
            };
            "gpt-oss:latest" = {
              name = "gpt-oss:latest";
              limit = { context = 32768; output = 16384; };
            };
            "qwen2.5-coder:14b" = {
              name = "qwen2.5-coder:14b";
              limit = { context = 32768; output = 16384; };
            };
            "qwen2.5-coder:32b" = {
              name = "qwen2.5-coder:32b";
              limit = { context = 32768; output = 16384; };
            };
            "qwen2.5-coder:latest" = {
              name = "qwen2.5-coder:latest";
              limit = { context = 32768; output = 16384; };
            };
            "mistral:latest" = {
              name = "mistral:latest";
              limit = { context = 32768; output = 16384; };
            };
            "llama3.1:latest" = {
              name = "llama3.1:latest";
              limit = { context = 32768; output = 16384; };
            };
          };
        };
      };
    };
  };
}
