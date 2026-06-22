## ADDED Requirements

### Requirement: OpenCode model list reflects locally available Ollama models

A mechanism SHALL exist to update the `models` map in the OpenCode config to match the output of `ollama list` on the current host.

#### Scenario: Script lists available models

- **WHEN** the update script runs
- **THEN** it SHALL call `ollama list` and produce a JSON fragment mapping each model tag to a display name

#### Scenario: New model appears after update

- **WHEN** a new model is pulled (`ollama pull <model>`) and the update mechanism is invoked
- **THEN** the new model SHALL appear in the OpenCode `/models` list
