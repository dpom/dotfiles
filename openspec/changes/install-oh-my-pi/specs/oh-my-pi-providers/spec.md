## ADDED Requirements

### Requirement: Dynamic Ollama provider discovery
Feature: oh-my-pi-providers
Rule: The module SHALL dynamically generate `.omp/agent/models.yml` at activation time by querying the local Ollama instance for available models.

#### Scenario: models.yml generated from Ollama
- **GIVEN** `dpom-oh-my-pi.enable = true`
- **WHEN** `home-manager switch` runs
- **THEN** the activation hook SHALL query `http://localhost:11434/api/tags`
- **THEN** each returned model SHALL be added to the `providers.ollama.models` array with `contextWindow: 65536` and `maxTokens: 32768`
- **THEN** if Ollama is unreachable, an empty model list SHALL be written

### Requirement: Dynamic LM Studio provider discovery
Feature: oh-my-pi-providers
Rule: The module SHALL dynamically generate `.omp/agent/models.yml` at activation time by querying the local LM Studio instance for available models.

#### Scenario: models.yml generated from LM Studio
- **GIVEN** `dpom-oh-my-pi.enable = true`
- **WHEN** `home-manager switch` runs
- **THEN** the activation hook SHALL query `http://localhost:1234/v1/models`
- **THEN** each returned model SHALL be added to the `providers.lmstudio.models` array with `contextWindow: 65536` and `maxTokens: 32768`

#### Scenario: LM Studio unreachable, empty model list
- **GIVEN** `dpom-oh-my-pi.enable = true`
- **WHEN** LM Studio is not running
- **THEN** the activation hook SHALL NOT fail
- **THEN** the `providers.lmstudio.models` array SHALL be empty
- **THEN** Ollama models SHALL still be populated normally

### Requirement: Cloud provider template entries
Feature: oh-my-pi-providers
Rule: The static template for oh-my-pi configuration SHALL include placeholder entries for cloud providers.

#### Scenario: Template contains cloud provider placeholders
- **GIVEN** the oh-my-pi config template
- **WHEN** inspected
- **THEN** it SHALL contain `anthropic` and `openai` provider entries under the `providers` key
- **THEN** cloud providers SHALL use OAuth authentication (no API key in config)
- **THEN** cloud provider models arrays SHALL be empty (user runs `omp setup` to configure)

### Requirement: Non-breaking coexistence with Ollama
Feature: oh-my-pi-providers
Rule: Adding new providers SHALL NOT alter existing provider configurations.

#### Scenario: Existing configs preserved
- **GIVEN** the existing oh-my-pi activation script generates `~/.omp/agent/models.yml`
- **WHEN** new providers are added
- **THEN** existing `providers.ollama` and `providers.lmstudio` entries SHALL remain unchanged
- **THEN** existing model discovery logic SHALL continue to work as before
