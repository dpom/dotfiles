## Context

Home Manager modules for OpenCode and PI agent each generate config files at activation time by querying local model providers. Currently both only query Ollama (`localhost:11434`). LM Studio is already installed as a package via `dpom-ai` but not configured as a model provider for either tool.

**Assumptions:**
- LM Studio runs at `http://localhost:1234/v1` (standard port)
- LM Studio exposes an OpenAI-compatible `/v1/models` endpoint for model discovery
- The user may run Ollama, LM Studio, both, or neither at any given time

```
+----------+         home-manager switch         +---------------------------+
|  User    | ----------------------------------> | Activation Scripts        |
+----------+     (triggers generation)           |                           |
                                                 |  +---------------------+  |
                                                 |  | generate-opencode-  |  |
                                                 |  | config              |  |
                                                 |  +---------------------+  |
                                                 |                           |
                                                 |  +---------------------+  |
                                                 |  | generate-pi-config  |  |
                                                 |  +---------------------+  |
                                                 +---------------------------+
                                                    |              |
                                                    | HTTP         | HTTP
                                                    v              v
                                            +-----------+    +-----------+
                                            | Ollama    |    | LM Studio |
                                            | :11434/v1 |    | :1234/v1  |
                                            +-----------+    +-----------+
                                                    |              |
                                                    | /api/tags    | /v1/models
                                                    v              v
                                            +-----------+    +-----------+
                                            | Tool      |    | Tool      |
                                            | Configs   |    | Configs   |
                                            |           |    |           |
                                            | opencode  |    | .pi/agent |
                                            | .json     |    | models.json|
                                            +-----------+    +-----------+
```

The activation scripts query both providers, collect model lists, and inject them into config templates. OpenCode and PI agent use these configs at runtime to offer the user a choice of model providers.

## Goals / Non-Goals

**Goals:**
- Add `lmstudio` as a second provider alongside `ollama` in the OpenCode V1 config template
- Add `lmstudio` as a second provider alongside `ollama` in the PI agent config template
- Dynamically discover LM Studio loaded models at activation time
- Gracefully handle LM Studio being unreachable (fall back to empty model list)
- Preserve all existing Ollama behavior unchanged

**Non-Goals:**
- V2 schema migration for OpenCode
- Adding other model providers (llama.cpp, vLLM, etc.)
- Hardcoding default models or model selection
- Configuring LM Studio itself (it is installed via `dpom-ai`)

## Decisions

| # | Decision | Rationale | Alternatives Considered |
|---|----------|-----------|------------------------|
| 1 | **Dynamic discovery via `/v1/models`** | LM Studio exposes standard OpenAI-compatible endpoint; consistency with Ollama approach; zero-maintenance when models change | Static model list (brittle, needs manual updates) |
| 2 | **Separate provider entry in templates** | Each provider has different base URL, API key, compat flags; keeps config clean | Merged provider (confusing, different endpoints) |
| 3 | **`openai-completions` API type (PI agent)** | LM Studio is OpenAI-compatible; matches Ollama's type | `anthropic-messages` (incompatible), `openai-responses` (different contract) |
| 4 | **`@ai-sdk/openai-compatible` npm package (OpenCode)** | Same package as Ollama uses; well-tested with OpenAI-compatible endpoints | Custom provider (unnecessary complexity) |
| 5 | **No default model selection for OpenCode** | Models are dynamic; user selects at runtime | Hardcoding `qwen3-coder` (may not be loaded) |
| 6 | **Graceful degradation when LM Studio is down** | Same pattern as Ollama; prevents activation failures if LM Studio isn't running | Hard failure (breaks `home-manager switch` if LM Studio is off) |

## Risks / Trade-offs

- **[Resilience] Both providers must be queried** -> if Ollama is up but LM Studio is down, the script succeeds with LM Studio models empty, and vice versa. Consider running queries in parallel (background `curl` + `wait`) to avoid sequential failure delay.
- **[Port collision] LM Studio on non-standard port** -> Assumes `:1234`. If the user changes it, they'd need to edit the template. No mitigation planned; port is standard.
- **[Naming collision] Same model name in both providers** -> Unique provider keys (`ollama` / `lmstudio`) differentiate them; no action needed.

## Migration Plan

1. Edit `Config.txt` (Org source for both `modules/home/opencode.nix` and `modules/home/pi.nix`)
2. Update `piConfigTemplate` to include `lmstudio` provider entry
3. Update `generatePiConfig` script to query LM Studio `/v1/models` in addition to Ollama `/api/tags`
4. Update `opencodeTemplate` to include `lmstudio` provider entry
5. Update `generateOpencodeConfig` script to query LM Studio `/v1/models` in addition to Ollama `/api/tags`
6. Run `ent generate` or `./bin/generate-admin` to tangle `.nix` files
7. Run `home-manager switch` to apply
8. **Rollback**: revert Org edits, retangle, and reapply

## Open Questions

None. All decisions resolved during design phase (no in-force ADRs exist for this area).
