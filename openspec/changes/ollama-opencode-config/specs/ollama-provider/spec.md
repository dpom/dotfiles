## ADDED Requirements

### Requirement: Declare Ollama as an OpenCode provider

The OpenCode global config SHALL include an `ollama` provider block using the `@ai-sdk/openai-compatible` npm adapter with `baseURL` pointing at `http://localhost:11434/v1`.

#### Scenario: Provider appears in `/models`

- **WHEN** OpenCode starts with the config containing the ollama provider
- **THEN** the `/models` command SHALL list locally declared models under the "Ollama (local)" provider

#### Scenario: Provider uses correct endpoint

- **WHEN** OpenCode sends a chat completion request via the ollama provider
- **THEN** the request SHALL be sent to `http://localhost:11434/v1`

### Requirement: Config is managed via Home Manager

The `~/.config/opencode/opencode.jsonc` file SHALL be generated from the dotfiles' Config.txt (Nix Home Manager config), not edited by hand.

#### Scenario: Config survives home-manager switch

- **WHEN** `home-manager switch` runs
- **THEN** the generated `opencode.jsonc` SHALL contain the declared ollama provider block
