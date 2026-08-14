## ADDED Requirements

### Requirement: ollama-cloud provider entry in OpenCode template
The OpenCode V1 config template SHALL include an `ollama-cloud` provider alongside the existing `ollama` and `lmstudio` providers, pointing at Ollama Cloud's OpenAI-compatible endpoint.
Feature: opencode-ollama-cloud

#### Scenario: Template includes ollama-cloud provider
- **GIVEN** the OpenCode template JSON
- **WHEN** the template is inspected
- **THEN** it SHALL contain an `ollama-cloud` provider entry under the `"provider"` key in addition to `ollama` and `lmstudio`
- **THEN** the `ollama-cloud` provider SHALL have `"npm": "@ai-sdk/openai-compatible"`
- **THEN** the `ollama-cloud` provider SHALL have `"name": "Ollama Cloud"`
- **THEN** the `ollama-cloud` provider SHALL have `"options.baseURL": "https://ollama.com/v1"`

### Requirement: Static free-tier model catalog in OpenCode
The `ollama-cloud` provider SHALL statically list the full free-tier model catalog with context/output limits, rather than discovering models at runtime.

#### Scenario: Template lists free-tier cloud models
- **GIVEN** the OpenCode template JSON
- **WHEN** the `provider.ollama-cloud.models` object is inspected
- **THEN** it SHALL contain entries for `gpt-oss:20b`, `gpt-oss:120b`, `nemotron-3-nano:30b`, `nemotron-3-super`, `gemma4:31b`, `qwen3.5:397b`, `deepseek-v4-flash:0731`, `deepseek-v4-flash:preview`, and `minimax-m2.7`
- **THEN** each model entry SHALL include `name` and `limit.context`/`limit.output` fields

### Requirement: API key injected from SOPS secret
The generated OpenCode config SHALL authenticate against Ollama Cloud using the `ollama_cloud_api_key` SOPS secret.

#### Scenario: API key present in generated config
- **GIVEN** the `ollama_cloud_api_key` SOPS secret is declared and decrypts successfully
- **WHEN** `home-manager switch` runs the OpenCode activation script
- **THEN** the generated `~/.config/opencode/opencode.json` SHALL contain the secret value in `provider.ollama-cloud.options.apiKey`
- **THEN** the API key SHALL NOT be committed to the repository

### Requirement: OpenCode default model points at a cloud model
The generated OpenCode config SHALL set a default model on the `ollama-cloud` provider.

#### Scenario: Default model configured
- **GIVEN** the OpenCode activation script generates `~/.config/opencode/opencode.json`
- **WHEN** the top-level `"model"` key is inspected
- **THEN** it SHALL equal `"ollama-cloud/gpt-oss:20b"`

### Requirement: Non-breaking coexistence with local providers
The `ollama-cloud` addition SHALL NOT alter the existing `ollama` or `lmstudio` provider configuration or their model discovery behavior.

#### Scenario: Local providers preserved
- **GIVEN** the OpenCode activation script generates `~/.config/opencode/opencode.json`
- **WHEN** the `ollama-cloud` provider is added
- **THEN** the `provider.ollama` and `provider.lmstudio` entries SHALL remain unchanged in structure and content
- **THEN** the existing local model discovery logic SHALL continue to run as before
