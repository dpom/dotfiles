## Context

Pi (`@earendil-works/pi-coding-agent`) is a TypeScript-based coding agent CLI. The current nixpkgs version (0.75.4) is outdated; the latest release is v0.80.3. The existing nixpkgs derivation uses `buildNpmPackage` with the pi monorepo source, which compiles TypeScript with `tsgo` and `npm run build`. Additionally, `pi-acp` (v0.0.31) provides an ACP adapter for agent-shell integration — also absent from nixpkgs at the desired version.

Both hosts (mary and bob) should have the `pi` CLI available in PATH, along with the ACP adapter and pre-configured Ollama model presets.

## Goals / Non-Goals

**Goals:**
- Provide `pi` CLI at v0.80.3 on both mary and bob
- Provide `pi-acp` ACP adapter at v0.0.31 alongside pi
- Pre-configure `.pi/agent/models.json` with local Ollama provider and model list
- Follow existing dotfiles conventions: Home Manager module with `dpom-<name>.enable` toggle
- Keep package definitions close to the module (inline `pkgs.buildNpmPackage`)

**Non-Goals:**
- Not packaging pi for Nixpkgs contribution (out of scope)
- No shell integration, completions, or additional config files for pi
- No containerization/sandboxing (pi runs with user permissions as documented)

## Decisions

1. **Custom `buildNpmPackage` derivations** — build both `pi-coding-agent` and `pi-acp` from source. `pi-coding-agent` uses `fetchFromGitHub` at tag `v0.80.3` with `packages/coding-agent` workspace; `pi-acp` uses `fetchFromGitHub` at tag `v0.0.31`.
2. **Inline in module** — both derivations live directly in `modules/home/pi.nix` using `pkgs.buildNpmPackage`, avoiding separate package files.
3. **`dpom-pi.enable` toggle** — standard pattern matching all other modules in the repo. Enables both packages and models.json.
4. **Add to `home.packages`** — include both packages in the user's PATH via Home Manager.
5. **Dynamic models.json via activation hook** — following the same pattern as opencode config generation. A `writeShellApplication` script queries `http://localhost:11434/api/tags` via `curl` + `jq`, transforms each model into the pi model format with default `contextWindow: 65536` and `maxTokens: 32768`, and merges them into a static provider template. Runs as a `home.activation` entry after `writeBoundary`.
6. **`nodejs` dependency** — `buildNpmPackage` pulls in nodejs as a build dependency; the resulting derivation bundles its own node runtime via the npm build output, so no runtime nodejs dependency is needed.
7. **postInstall symlink fix** — pi-coding-agent's build has dangling symlinks to monorepo workspace packages; the derivation removes and replaces them with real copies in postInstall.
8. **postFixup PATH wrap** — wrap the `pi` binary to include `ripgrep` and `fd` in PATH at runtime.

## Risks / Trade-offs

- **npmDepsHash maintenance** — each version bump requires updating the npm dependency hash. Mitigation: document how to update the hash using `nix build` with `--impure` to get the correct hash.
- **nixpkgs already has pi** — existing users might expect `pkgs.pi-coding-agent` to work. This custom package overrides it only in this flake's scope, so no conflict.
- **Upstream build changes** — if pi changes its build system, the derivation may break. Mitigation: pin to a working release and test on update.
- **models.json depends on Ollama at activation time** — if Ollama is down during `home-manager switch`, the model list will be empty. Mitigation: fallback to empty array if curl fails; re-run `generate-pi-config` manually after Ollama starts.

## Migration Plan

1. Create `modules/home/pi.nix` with inline `buildNpmPackage` derivations for both packages, `dpom-pi.enable` option, and models.json config
2. Add `./pi.nix` to `modules/home/default.nix` imports
3. Add `dpom-pi.enable = true;` to `hosts/mary/home.nix` and `hosts/bob/home.nix`
4. Run `home-manager switch` on both hosts to apply

Rollback: remove the enable line and re-run `home-manager switch`.

## Open Questions

None — all design decisions were resolved during the proposal phase.
