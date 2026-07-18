## ADDED Requirements

### Requirement: Dynamic LM Studio provider presets
Feature: pi-coding-agent
Rule: The module SHALL dynamically generate `.pi/agent/models.json` at activation time with both Ollama and LM Studio provider entries, querying both local instances for available models.

#### Scenario: models.json generated from both providers
- **GIVEN** `dpom-pi.enable = true`
- **WHEN** `home-manager switch` runs
- **THEN** the activation hook SHALL query `http://localhost:11434/api/tags` for Ollama models
- **THEN** the activation hook SHALL query `http://localhost:1234/v1/models` for LM Studio models
- **THEN** each returned Ollama model SHALL be added to the `providers.ollama.models` array with `contextWindow: 65536` and `maxTokens: 32768`
- **THEN** each returned LM Studio model SHALL be added to the `providers.lmstudio.models` array with `contextWindow: 65536` and `maxTokens: 32768`

#### Scenario: LM Studio unreachable, empty model list
- **GIVEN** `dpom-pi.enable = true`
- **WHEN** LM Studio is not running
- **THEN** the activation hook SHALL NOT fail
- **THEN** the `providers.lmstudio.models` array SHALL be empty
- **THEN** Ollama models SHALL still be populated normally

### Requirement: LM Studio template entry in PI config
The static template for PI agent configuration SHALL include an `lmstudio` provider entry.

#### Scenario: Template contains both providers
- **GIVEN** the PI config template
- **WHEN** inspected
- **THEN** it SHALL contain both `ollama` and `lmstudio` provider entries under the `"providers"` key
- **THEN** the `lmstudio` provider SHALL have `"baseUrl": "http://localhost:1234/v1"`
- **THEN** the `lmstudio` provider SHALL have `"api": "openai-completions"`
- **THEN** the `lmstudio` provider SHALL have `"apiKey": "lm-studio"`
- **THEN** the `lmstudio` provider SHALL have `"compat.supportsDeveloperRole": true`
- **THEN** the `lmstudio` provider SHALL have `"compat.supportsReasoningEffort": false`
- **THEN** the `lmstudio` provider models array SHALL be dynamically populated (not hardcoded)

### Requirement: Non-breaking coexistence with Ollama
The LM Studio addition SHALL NOT alter the existing Ollama provider's configuration or behavior.

#### Scenario: Ollama config preserved
- **GIVEN** the existing PI activation script generates `~/.pi/agent/models.json`
- **WHEN** LM Studio support is added
- **THEN** the `providers.ollama` entry SHALL remain unchanged in structure and content
- **THEN** the existing Ollama model discovery logic SHALL continue to work as before
