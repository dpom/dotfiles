# llama-cpp-server

## ADDED Requirements

### Requirement: Local llama.cpp service on mary
The system SHALL provide a NixOS module option `dpom-llama-cpp.enable` that runs a llama.cpp OpenAI-compatible server on mary, bound to `127.0.0.1:8080`.

#### Scenario: Mary enables the server
- **GIVEN** the mary host configuration sets `dpom-llama-cpp.enable = true`
- **WHEN** the system configuration is applied
- **THEN** the llama.cpp service SHALL be enabled
- **AND** the service SHALL listen on `127.0.0.1:8080`

#### Scenario: Bob does not run the server
- **GIVEN** the bob host configuration does not enable `dpom-llama-cpp`
- **WHEN** the system configuration is applied on bob
- **THEN** no llama.cpp service SHALL be configured or started

#### Scenario: Module disabled
- **GIVEN** `dpom-llama-cpp.enable = false`
- **WHEN** the system configuration is applied
- **THEN** no llama.cpp service SHALL be configured or started

### Requirement: ROCm acceleration for the Radeon 890M
The server SHALL use the ROCm backend and offload inference to the integrated Radeon 890M using the native `gfx1150` target without an architecture override.

#### Scenario: ROCm backend selected
- **GIVEN** `dpom-llama-cpp.acceleration = "rocm"` on mary
- **WHEN** the llama.cpp package is built and the service starts
- **THEN** the package SHALL include ROCm support targeted at `gfx1150`
- **AND** the server logs SHALL report a ROCm device used for inference

#### Scenario: Native gfx1150 without override
- **GIVEN** mary uses the Radeon 890M at `gfx1150`
- **WHEN** the llama.cpp service starts
- **THEN** `HSA_OVERRIDE_GFX_VERSION` SHALL NOT be set
- **AND** ROCm SHALL use the native `gfx1150` instruction set

### Requirement: Localhost-only API exposure
The llama.cpp API SHALL be reachable only from the local host and SHALL NOT require an API key for localhost requests.

#### Scenario: Local client reaches the API
- **GIVEN** the llama.cpp service is running on mary
- **WHEN** a client on mary requests `http://127.0.0.1:8080/health`
- **THEN** the request SHALL succeed without an API key

#### Scenario: Remote client cannot reach the API
- **GIVEN** the llama.cpp service is running on mary
- **WHEN** a client on another host requests port 8080 on mary
- **THEN** the connection SHALL be refused or timed out
- **AND** no firewall port SHALL be opened for llama.cpp

### Requirement: OpenAI-compatible inference endpoints
The server SHALL expose OpenAI-compatible model discovery and chat completion endpoints using the configured model alias.

#### Scenario: Model discovery returns the configured alias
- **GIVEN** the server is running with the alias `qwen3-coder-30b-a3b-instruct`
- **WHEN** a client requests `GET /v1/models`
- **THEN** the response SHALL list `qwen3-coder-30b-a3b-instruct`

#### Scenario: Chat completion returns generated text
- **GIVEN** the server is running and the model is loaded
- **WHEN** a client sends a chat completion request to `/v1/chat/completions`
- **THEN** the response SHALL contain generated assistant text
- **AND** streaming responses SHALL be supported

#### Scenario: Tool calls are honored
- **GIVEN** the server is running with Jinja chat-template support
- **WHEN** a chat completion request includes tool definitions and the model selects a tool
- **THEN** the response SHALL contain a tool call with a name and arguments

### Requirement: Code-focused model provisioning
The server SHALL serve `Qwen3-Coder-30B-A3B-Instruct` from a service-readable GGUF and SHALL NOT depend on model files under `/home`.

#### Scenario: Default model is served
- **GIVEN** the llama.cpp service starts with the default model configuration
- **WHEN** the model is loaded
- **THEN** the served model SHALL be `Qwen3-Coder-30B-A3B-Instruct`
- **AND** the preferred quantization SHALL be `UD-Q4_K_XL` or `Q4_K_M`

#### Scenario: Model path is readable by the service
- **GIVEN** the llama.cpp service runs with `ProtectHome=true`
- **WHEN** the service loads the model
- **THEN** the model SHALL reside in a service-readable location such as `/var/lib/llama-cpp` or `/var/cache/llama-cpp`
- **AND** the service SHALL NOT read the model from `/home`

#### Scenario: Model provisioning failure is isolated
- **GIVEN** the model cannot be downloaded or loaded
- **WHEN** the llama.cpp service starts
- **THEN** the failure SHALL be reported in the service log
- **AND** the Ollama service SHALL remain running and reachable on port 11434

### Requirement: Memory coexistence with Ollama
The server SHALL run with bounded memory use so that it can operate while Ollama remains enabled on mary.

#### Scenario: Both inference services run concurrently
- **GIVEN** both llama.cpp and Ollama are enabled on mary
- **WHEN** both services are running
- **THEN** Ollama SHALL remain reachable on `127.0.0.1:11434`
- **AND** llama.cpp SHALL remain reachable on `127.0.0.1:8080`

#### Scenario: Bounded context and single slot
- **GIVEN** the llama.cpp service starts on mary
- **WHEN** the server configuration is inspected
- **THEN** the server SHALL use one inference slot
- **AND** the context length SHALL be at most 65536 tokens
- **AND** the server SHALL NOT preload an additional model

### Requirement: Startup health and coherent output
The server SHALL report healthy startup and SHALL return coherent output from a smoke prompt before a deployment is accepted.

#### Scenario: Health endpoint reports ready
- **GIVEN** the llama.cpp service has started and loaded the model
- **WHEN** a client requests `GET /health`
- **THEN** the response SHALL indicate that the server is ready

#### Scenario: Smoke prompt returns coherent text
- **GIVEN** the server is healthy
- **WHEN** a smoke prompt is sent to the chat completion endpoint
- **THEN** the response SHALL be coherent text rather than repeated or random tokens

#### Scenario: Corrupted ROCm output blocks acceptance
- **GIVEN** the ROCm build returns incoherent output
- **WHEN** the smoke prompt is evaluated
- **THEN** the deployment SHALL NOT be accepted
- **AND** the operator SHALL switch to Vulkan or a newer llama.cpp build
