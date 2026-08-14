# pi-ollama-cloud Specification

## Purpose
TBD - created by archiving change opencode-pi-ollama-cloud. Update Purpose after archive.

## Requirements

### Requirement: ollama-cloud provider entry in PI config template
The PI agent config template SHALL include an `ollama-cloud` provider alongside the existing `ollama` and `lmstudio` providers, pointing at Ollama Cloud's OpenAI-compatible endpoint.
Feature: pi-ollama-cloud

#### Scenario: Template includes ollama-cloud provider
- **GIVEN** the PI config template
- **WHEN** inspected
- **THEN** it SHALL contain an `ollama-cloud` provider entry under the `"providers"` key in addition to `ollama` and `lmstudio`
- **THEN** the `ollama-cloud` provider SHALL have `"baseUrl": "https://ollama.com/v1"`
- **THEN** the `ollama-cloud` provider SHALL have `"api": "openai-completions"`

### Requirement: Static free-tier model catalog in PI config
The `ollama-cloud` provider SHALL statically list the full free-tier model catalog with context window and max tokens, rather than discovering models at runtime.

#### Scenario: Template lists free-tier cloud models
- **GIVEN** the PI config template
- **WHEN** the `providers.ollama-cloud.models` array is inspected
- **THEN** it SHALL contain entries for `gpt-oss:20b`, `gpt-oss:120b`, `nemotron-3-nano:30b`, `nemotron-3-super`, `gemma4:31b`, `qwen3.5:397b`, `deepseek-v4-flash:0731`, `deepseek-v4-flash:preview`, and `minimax-m2.7`
- **THEN** each model entry SHALL include `id`, `name`, `contextWindow`, and `maxTokens` fields

### Requirement: API key injected from SOPS secret
The generated PI config SHALL authenticate against Ollama Cloud using the `ollama_cloud_api_key` SOPS secret.

#### Scenario: API key present in generated config
- **GIVEN** the `ollama_cloud_api_key` SOPS secret is declared and decrypts successfully
- **WHEN** `home-manager switch` runs the PI activation script
- **THEN** the generated `~/.pi/agent/models.json` SHALL contain the secret value in `providers.ollama-cloud.apiKey`
- **THEN** the API key SHALL NOT be committed to the repository

### Requirement: Non-breaking coexistence with local providers
The `ollama-cloud` addition SHALL NOT alter the existing `ollama` or `lmstudio` provider configuration or their model discovery behavior.

#### Scenario: Local providers preserved
- **GIVEN** the PI activation script generates `~/.pi/agent/models.json`
- **WHEN** the `ollama-cloud` provider is added
- **THEN** the `providers.ollama` and `providers.lmstudio` entries SHALL remain unchanged in structure and content
- **THEN** the existing local model discovery logic SHALL continue to run as before

### Requirement: PI default provider and model unchanged
Adding `ollama-cloud` SHALL NOT change PI's active default provider/model.

#### Scenario: Default remains on local model
- **GIVEN** `~/.pi/agent/settings.json` declares `defaultProvider: "ollama"` and `defaultModel: "muse-glimmer:latest"`
- **WHEN** the `ollama-cloud` provider is added
- **THEN** the `defaultProvider` and `defaultModel` settings SHALL remain unchanged
