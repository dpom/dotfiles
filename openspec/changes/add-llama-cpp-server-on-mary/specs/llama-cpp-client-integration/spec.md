# llama-cpp-client-integration

## ADDED Requirements

### Requirement: OpenCode llama.cpp provider
The generated OpenCode configuration SHALL include a `llama-cpp` provider that targets the local llama.cpp endpoint and lists the served model statically.

#### Scenario: Provider entry is generated
- **GIVEN** `dpom-opencode.enable = true`
- **WHEN** the OpenCode configuration is generated
- **THEN** the configuration SHALL contain a `llama-cpp` provider
- **AND** the provider SHALL use `@ai-sdk/openai-compatible`
- **AND** the provider base URL SHALL be `http://127.0.0.1:8080/v1`
- **AND** the provider SHALL list `qwen3-coder-30b-a3b-instruct` with context and output limits

#### Scenario: Server unavailability does not break generation
- **GIVEN** the llama.cpp server is not running
- **WHEN** the OpenCode configuration is generated
- **THEN** generation SHALL succeed
- **AND** the `llama-cpp` provider SHALL remain configured with its static model entry

### Requirement: OpenCode provider coexistence
Adding the llama.cpp provider SHALL NOT alter the existing OpenCode providers or the default model.

#### Scenario: Existing providers are preserved
- **GIVEN** the OpenCode configuration already contains `ollama`, `lmstudio`, and `ollama-cloud` providers
- **WHEN** the `llama-cpp` provider is added
- **THEN** the existing provider entries SHALL remain unchanged in structure and content

#### Scenario: Default model is unchanged
- **GIVEN** the generated OpenCode configuration
- **WHEN** the top-level `model` key is inspected
- **THEN** it SHALL remain `opencode/big-pickle`

### Requirement: gptel llama.cpp backend
The Emacs configuration SHALL register a gptel backend for the local llama.cpp endpoint.

#### Scenario: Backend is registered
- **GIVEN** Emacs loads the gptel configuration
- **WHEN** the registered backends are inspected
- **THEN** a backend named `llama.cpp` SHALL exist
- **AND** it SHALL target `localhost:8080`
- **AND** it SHALL use the model alias `qwen3-coder-30b-a3b-instruct`
- **AND** it SHALL enable streaming

#### Scenario: Emacs startup does not require the server
- **GIVEN** the llama.cpp server is not running
- **WHEN** Emacs loads the gptel configuration
- **THEN** Emacs startup SHALL succeed
- **AND** the `llama.cpp` backend SHALL remain registered for later use

### Requirement: gptel llama.cpp preset
The Emacs configuration SHALL provide a gptel preset that selects the llama.cpp backend and its code-focused model.

#### Scenario: Preset selects the llama.cpp backend
- **GIVEN** the gptel presets are loaded
- **WHEN** the llama.cpp preset is selected
- **THEN** the active backend SHALL be `llama.cpp`
- **AND** the active model SHALL be `qwen3-coder-30b-a3b-instruct`

#### Scenario: Existing gptel behavior is preserved
- **GIVEN** the existing `Ollama` backend and its presets
- **WHEN** the llama.cpp backend and preset are added
- **THEN** the existing `Ollama` backend SHALL remain registered
- **AND** the existing presets SHALL remain available
- **AND** the default gptel backend SHALL remain `Ollama`

### Requirement: Consistent model alias across clients
All clients SHALL use the same model alias that the llama.cpp server exposes.

#### Scenario: Client aliases match the server
- **GIVEN** the llama.cpp server exposes the alias `qwen3-coder-30b-a3b-instruct`
- **WHEN** the OpenCode provider and gptel backend are inspected
- **THEN** both clients SHALL use `qwen3-coder-30b-a3b-instruct` as the model identifier
