## Context

Pi (`@earendil-works/pi-coding-agent`) is a TypeScript-based coding agent CLI. The current nixpkgs version (0.75.4) is outdated; the latest release is v0.80.3. The existing nixpkgs derivation uses `buildNpmPackage` with the pi monorepo source, which compiles TypeScript with `tsgo` and `npm run build`.

Both hosts (mary and bob) should have the `pi` CLI available in PATH.

## Goals / Non-Goals

**Goals:**
- Provide `pi` CLI at v0.80.3 on both mary and bob
- Follow existing dotfiles conventions: Home Manager module with `dpom-<name>.enable` toggle
- Keep the package definition close to the module (inline `pkgs.buildNpmPackage`)

**Non-Goals:**
- Not packaging pi for Nixpkgs contribution (out of scope)
- No shell integration, completions, or config files for pi
- No containerization/sandboxing (pi runs with user permissions as documented)

## Decisions

1. **Custom `buildNpmPackage` derivation** — override nixpkgs' `pi-coding-agent` with a newer version. Use the same build structure as the existing nixpkgs derivation but point `src` at `fetchFromGitHub` at tag `v0.80.3`.
2. **Inline in module** — the derivation lives directly in `modules/home/pi.nix` using `pkgs.buildNpmPackage`, avoiding a separate package file.
3. **`dpom-pi.enable` toggle** — standard pattern matching all other modules in the repo.
4. **Add to `home.packages`** — simply include the package in the user's PATH via Home Manager.
5. **`nodejs` dependency** — `buildNpmPackage` pulls in nodejs as a build dependency; the resulting derivation bundles its own node runtime via the npm build output, so no runtime nodejs dependency is needed.

## Risks / Trade-offs

- **npmDepsHash maintenance** — each version bump requires updating the npm dependency hash. Mitigation: document how to update the hash using `nix build` with `--impure` to get the correct hash.
- **nixpkgs already has pi** — existing users might expect `pkgs.pi-coding-agent` to work. This custom package overrides it only in this flake's scope, so no conflict.
- **Upstream build changes** — if pi changes its build system, the derivation may break. Mitigation: pin to a working release and test on update.

## Migration Plan

1. Create `modules/home/pi.nix` with inline `buildNpmPackage` derivation and `dpom-pi.enable` option
2. Add `./pi.nix` to `modules/home/default.nix` imports
3. Add `dpom-pi.enable = true;` to `hosts/mary/home.nix` and `hosts/bob/home.nix`
4. Run `home-manager switch` on both hosts to apply

Rollback: remove the enable line and re-run `home-manager switch`.

## Open Questions

None — all design decisions were resolved during the proposal phase.
