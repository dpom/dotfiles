## ADDED Requirements

### Requirement: OpenCode model list reflects locally available Ollama models

A mechanism SHALL exist to update the `models` map in the OpenCode config to match the models served by the local Ollama instance.

#### Scenario: Activation script discovers models at switch time

- **WHEN** `home-manager switch` runs
- **THEN** the activation script SHALL query `http://localhost:11434/api/tags` and produce a JSON object mapping each model tag to its metadata

#### Scenario: New model appears after home-manager switch

- **WHEN** a new model is pulled (`ollama pull <model>`) and `home-manager switch` runs
- **THEN** the new model SHALL appear in the OpenCode `/models` list

#### Scenario: Standalone script for manual updates

- **WHEN** `bin/update-opencode-models` runs
- **THEN** it SHALL call `ollama list` and output a JSON fragment mapping each model tag to its metadata
