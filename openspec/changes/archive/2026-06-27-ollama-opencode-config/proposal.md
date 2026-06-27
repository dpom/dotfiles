## Why

OpenCode is configured with a bare `opencode.jsonc` (schema only), so every session defaults to cloud providers. The system already runs Ollama locally (port 11434, with local models) and has Ollama wired into Emacs/gptel. Adding an Ollama provider to OpenCode lets coding sessions run entirely on local hardware — no API keys, no data leaving the machine, no cloud costs.

## What Changes

1. **Global OpenCode config** (`~/.config/opencode/opencode.json`) — add an `ollama` provider pointing at `localhost:11434/v1`, with locally available models declared.
2. **Dotfiles management** — a new `dpom-opencode` Home Manager module in `Config.txt` so the config survives `home-manager switch`.
3. **Dynamic model discovery** — an activation hook in the `dpom-opencode` module that queries the Ollama API at `http://localhost:11434/api/tags` and populates the model list, avoiding hardcoded stale model lists.

## Capabilities

### New Capabilities

- `ollama-provider`: Declare the Ollama OpenAI-compatible provider in OpenCode's global config, pointing at the local Ollama endpoint.
- `model-discovery`: Dynamically pull available Ollama models into the OpenCode config so new/removed models are reflected without manual edits.

### Modified Capabilities

- *(none — no existing specs are changing)*

## Impact

- `~/.config/opencode/opencode.json` — created/populated with provider block
- `Config.txt` / `modules/home/opencode.nix` — new `dpom-opencode` Home Manager module
- `bin/update-opencode-models` — standalone helper script (alternative to the activation hook)
- Ollama service must be running on the host for the provider to work (already true on both `mary` and `bob`)
