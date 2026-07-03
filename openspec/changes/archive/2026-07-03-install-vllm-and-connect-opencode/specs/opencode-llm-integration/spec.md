## ADDED Requirements

### Requirement: Local LLM provider in opencode
Feature: OpenCode Provider Configuration
Rule: OpenCode must be configured to use the local LLM endpoint on each machine

#### Scenario: OpenCode uses vLLM on mary
- **GIVEN** the hostname is `mary`
- **WHEN** opencode starts
- **THEN** the active provider points to `http://localhost:8000/v1`

#### Scenario: OpenCode uses Ollama on bob
- **GIVEN** the hostname is `bob`
- **WHEN** opencode starts
- **THEN** the active provider points to `http://localhost:11434/v1`

#### Scenario: Chat completion via local provider
- **GIVEN** opencode is configured with the local provider
- **WHEN** the user sends a prompt
- **THEN** the request is sent to the local LLM API endpoint
- **AND** the response is displayed to the user

### Requirement: Host-aware configuration
Feature: Per-Machine Configuration
Rule: The opencode config must route requests to the correct local service per host

#### Scenario: Configuration differs per host
- **GIVEN** the same dotfiles repo is deployed on both mary and bob
- **WHEN** opencode reads its configuration
- **THEN** mary uses the vLLM endpoint
- **AND** bob uses the Ollama endpoint
