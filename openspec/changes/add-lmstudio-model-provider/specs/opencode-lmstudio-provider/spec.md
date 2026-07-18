## ADDED Requirements

### Requirement: LM Studio provider entry in OpenCode template
Feature: opencode-lmstudio-provider
Rule: The OpenCode V1 config template SHALL include an `lmstudio` provider alongside the existing `ollama` provider.

#### Scenario: Template includes both providers
- **GIVEN** the OpenCode template JSON
- **WHEN** the template is inspected
- **THEN** it SHALL contain both an `ollama` provider entry and an `lmstudio` provider entry under the `"provider"` key
- **THEN** the `lmstudio` provider SHALL have `"npm": "@ai-sdk/openai-compatible"`
- **THEN** the `lmstudio` provider SHALL have `"name": "LM Studio (local)"`
- **THEN** the `lmstudio` provider SHALL have `"options.baseURL": "http://localhost:1234/v1"`
- **THEN** the `lmstudio` provider SHALL have an empty `"models": {}` placeholder for dynamic population

### Requirement: Dynamic LM Studio model discovery in OpenCode
The activation script SHALL query the local LM Studio instance for available models and inject them into the OpenCode config.

#### Scenario: models discovered from LM Studio API
- **GIVEN** LM Studio is running at `http://localhost:1234`
- **WHEN** `home-manager switch` triggers the OpenCode activation script
- **THEN** the script SHALL query `http://localhost:1234/v1/models`
- **THEN** each returned model SHALL be added to the `provider.lmstudio.models` object with `name` and `limit.context`/`limit.output` fields
- **THEN** both Ollama and LM Studio provider configs SHALL be written to `~/.config/opencode/opencode.json`

#### Scenario: LM Studio unreachable, empty model list
- **GIVEN** LM Studio is not running
- **WHEN** `home-manager switch` runs
- **THEN** the script SHALL NOT fail
- **THEN** the `lmstudio` provider SHALL have an empty models object `{}`
- **THEN** the Ollama provider config SHALL still be generated normally

### Requirement: Non-breaking coexistence with Ollama
The LM Studio addition SHALL NOT alter the existing Ollama provider's configuration or behavior.

#### Scenario: Ollama config preserved
- **GIVEN** the existing OpenCode activation script generates `~/.config/opencode/opencode.json`
- **WHEN** LM Studio support is added
- **THEN** the `provider.ollama` entry SHALL remain unchanged in structure and content
- **THEN** the existing Ollama model discovery logic SHALL continue to work as before
