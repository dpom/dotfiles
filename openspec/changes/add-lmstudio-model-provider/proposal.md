## Why

LM Studio provides local OpenAI-compatible model serving with GPU acceleration, offering an alternative to Ollama for running local models. The tool is already installed via the `dpom-ai` module but neither OpenCode nor the PI agent are configured to use it as a model provider, limiting the user's flexibility to choose between local inference backends.

## What Changes

- Add `lmstudio` provider entry to the OpenCode V1 config template (`modules/home/opencode.nix`), configured with dynamic model discovery via LM Studio's `/v1/models` endpoint
- Add `lmstudio` provider entry to the PI agent config template (`modules/home/pi.nix`), configured with dynamic model discovery via LM Studio's `/v1/models` endpoint
- Both provider entries use standard LM Studio endpoint: `http://localhost:1234/v1`, OpenAI-compatible API type
- No breaking changes; Ollama provider entries remain unchanged

## Capabilities

### New Capabilities
- `opencode-lmstudio-provider`: LM Studio provider configuration for OpenCode, dynamically discovered from the local LM Studio instance at activation time

### Modified Capabilities
- `pi-coding-agent`: Add LM Studio provider alongside the existing Ollama provider in the PI agent configuration template, with dynamically discovered models

## Impact

- `modules/home/opencode.nix`: Template expanded to include `lmstudio` provider entry; activation script updated to query both Ollama and LM Studio
- `modules/home/pi.nix`: Template expanded to include `lmstudio` provider entry; activation script updated to query both Ollama and LM Studio
- `Config.txt`: Both modules must be edited in Org mode and tangled to regenerate the `.nix` files
- No new dependencies; both modules already have `curl` and `jq` for dynamic queries
