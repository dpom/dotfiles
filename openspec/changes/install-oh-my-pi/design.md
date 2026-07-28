## Context

The dotfiles repository already manages two coding agents via Home Manager:
- **Pi** (`dpom-pi`): Built from `earendil-works/pi` v0.80.3, binary `pi`, config at `~/.pi/agent/`
- **OpenCode** (`dpom-opencode`): Uses `programs.opencode`, config at `~/.config/opencode/`

oh-my-pi is a fork of Pi with enhanced capabilities (hashline edits, native LSP/DAP, in-process ripgrep/glob, 40+ providers). It uses binary `omp` and config at `~/.omp/agent/`, so it can coexist with Pi.

**Architecture (lightweight):**

```
┌─────────────────────────────────────────────────────────────┐
│                    Home Manager Modules                      │
├─────────────────┬─────────────────┬─────────────────────────┤
│  dpom-pi        │  dpom-omp       │  dpom-opencode          │
│  (existing)     │  (new)          │  (existing)             │
├─────────────────┼─────────────────┼─────────────────────────┤
│  pi binary      │  omp binary     │  opencode binary        │
│  ~/.pi/agent/   │  ~/.omp/agent/  │  ~/.config/opencode/    │
│  pi-acp         │  (built-in)     │  (n/a)                  │
└─────────────────┴─────────────────┴─────────────────────────┘
         │                │                   │
         ▼                ▼                   ▼
    ┌─────────┐    ┌───────────┐        ┌─────────┐
    │ Ollama  │    │ Ollama    │        │ Ollama  │
    │ LM St.  │    │ LM Studio │        │ LM St.  │
    │ Cloud   │    │ Cloud     │        │         │
    └─────────┘    └───────────┘        └─────────┘
```

**Assumptions:**
- oh-my-pi can be built from source using `pkgs.buildNpmPackage` (same pattern as existing Pi module)
- oh-my-pi's config format is YAML (`models.yml`), requiring different template logic than Pi's JSON
- Shell completions are generated at build time, not runtime

## Goals / Non-Goals

**Goals:**
- Install oh-my-pi CLI (`omp`) via Home Manager as a Nix package
- Dynamic provider discovery for Ollama, LM Studio, and cloud providers
- Shell completions for bash, zsh, and fish
- Coexist with existing Pi module (no conflicts)

**Non-Goals:**
- Modifying or replacing the existing Pi module
- Configuring specific cloud provider API keys (handled via SOPS separately)
- Migrating existing Pi sessions or configs
- Enabling oh-my-pi by default on any host

## Decisions

### 1. Separate module file (`oh-my-pi.nix`)

**Decision:** Create `modules/home/oh-my-pi.nix` as a new file rather than extending `pi.nix`.

**Rationale:** 
- Follows existing pattern (opencode.nix, gemini.nix are separate modules)
- Keeps concerns separated — Pi and oh-my-pi are different agents
- Allows independent enable/disable per host
- No risk of breaking existing Pi functionality

**Alternatives considered:**
- Extend `pi.nix` with a mode selector — rejected (violates single-responsibility)
- Single module with both agents — rejected (too complex, different config formats)

### 2. Package build: `buildNpmPackage`

**Decision:** Build oh-my-pi from source using `pkgs.buildNpmPackage`, fetching from `github:can1357/oh-my-pi`.

**Rationale:**
- Consistent with existing Pi module pattern
- Pinned version ensures reproducibility
- No need to add as flake input (avoids flake.lock churn)

**Alternatives considered:**
- Add as flake input — rejected (unnecessary complexity, version pinning is sufficient)
- Use `pkgs.runCommand` with prebuilt binary — rejected (no prebuilt Linux binaries available)

### 3. Config format: YAML template + activation script

**Decision:** Use `pkgs.writeText` for a YAML template and a `writeShellApplication` script to populate it at activation time.

**Rationale:**
- oh-my-pi uses `~/.omp/agent/models.yml` (YAML format)
- Dynamic model discovery requires runtime queries to Ollama/LM Studio
- Activation hook pattern matches existing Pi and OpenCode modules

**Alternatives considered:**
- Use Nix `builtins.toYAML` — rejected (limited control over formatting)
- Use `yq` instead of `jq` — rejected (jq is already in closure, yq adds dependency)

### 4. Provider configuration: Extend to include cloud providers

**Decision:** Template includes placeholder entries for Anthropic and OpenAI alongside Ollama/LM Studio.

**Rationale:**
- User wants both local and cloud models
- Cloud providers use OAuth (no API key needed in config)
- Template provides structure; user runs `omp setup` for OAuth flows

**Alternatives considered:**
- SOPS secrets for API keys — rejected (oh-my-pi uses OAuth for most cloud providers)
- Only local providers — rejected (user explicitly wants cloud support)

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| oh-my-pi upstream breaks build | Pin to specific commit/tag; monitor releases |
| YAML template formatting issues | Use `pkgs.writeText` for static parts; dynamic parts via jq/yq |
| Config path conflicts with Pi | Different paths (`~/.omp/` vs `~/.pi/`); no conflict |
| Shell completions add closure size | Completions are small text files; negligible impact |

## Migration Plan

1. Create `modules/home/oh-my-pi.nix`
2. Add import to `modules/home/default.nix`
3. Enable `dpom-oh-my-pi.enable = true` in `hosts/mary/home.nix` and `hosts/bob/home.nix`
4. Run `ent generate` to tangle
5. Run `home-manager switch` on each host
6. Verify: `omp --version` works, `omp completions bash` generates output

**Rollback:** Disable `dpom-oh-my-pi.enable` and re-apply. No data migration needed (config is separate).

## Open Questions (Resolved)

- **Shell completions**: Added to `.bashrc` automatically via activation hook
- **Config generation**: Separate `generate-omp-config` script, runs at activation time (same pattern as Pi module)
