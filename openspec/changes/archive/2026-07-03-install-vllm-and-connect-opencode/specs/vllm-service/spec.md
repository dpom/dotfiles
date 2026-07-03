## ADDED Requirements

### Requirement: vLLM service lifecycle
Feature: vLLM Service
Rule: The vLLM inference server must run as a NixOS-managed systemd service on mary

#### Scenario: Service starts on boot
- **GIVEN** the system is booting
- **WHEN** NixOS activates the vllm service
- **THEN** the vllm systemd service starts automatically
- **AND** the service listens on port 8000

#### Scenario: Service restarts on failure
- **GIVEN** the vllm service is running
- **WHEN** the vllm process exits unexpectedly
- **THEN** systemd restarts the service within 5 seconds

#### Scenario: Service disabled via config
- **GIVEN** `dpom-vllm.enable` is set to `false`
- **WHEN** NixOS rebuilds and activates
- **THEN** the vllm service is stopped
- **AND** the service is disabled on subsequent boots

### Requirement: OpenAI-compatible API
Feature: OpenAI-Compatible Endpoint
Rule: vLLM must expose a valid OpenAI-compatible chat completions API

#### Scenario: Chat completion request succeeds
- **GIVEN** vLLM is running with a loaded model
- **WHEN** a client sends `POST /v1/chat/completions` with a valid chat messages payload
- **THEN** the response includes `choices` with at least one generated message
- **AND** the response status is 200

#### Scenario: Model listing returns available models
- **GIVEN** vLLM is running
- **WHEN** a client sends `GET /v1/models`
- **THEN** the response includes a list of models
- **AND** each model has `id`, `object`, and `created` fields

### Requirement: ROCm GPU acceleration
Feature: ROCm GPU Acceleration
Rule: On mary, vLLM must leverage the AMD iGPU via ROCm for inference

#### Scenario: ROCm devices detected at startup
- **GIVEN** mary has an AMD iGPU with ROCm drivers installed
- **WHEN** vLLM starts
- **THEN** vLLM logs that GPU is available
- **AND** inference runs on the GPU

#### Scenario: Fallback to CPU when GPU unavailable
- **GIVEN** `dpom-vllm.acceleration` is set to `null`
- **WHEN** vLLM starts
- **THEN** inference runs on CPU only

### Requirement: Firewall port access
Feature: Firewall Configuration
Rule: Port 8000 must be accessible on mary for API clients

#### Scenario: Port 8000 is open on mary
- **GIVEN** mary's NixOS configuration enables `dpom-vllm`
- **WHEN** checking `networking.firewall.allowedTCPPorts`
- **THEN** port 8000 is included in the list
