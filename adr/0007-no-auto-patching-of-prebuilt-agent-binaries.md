# Never Auto-Patch Prebuilt Agent Binaries; Repoint the Interpreter Explicitly and Verify the Version at Build Time

## Status

Accepted

## Date

2026-09-30

## Context

ADR-0006 pins `opencode` to a prebuilt release asset rather than a source build. That asset is a Bun single-file executable with two properties that matter under Nix, both established by building against upstream `v1.18.33` on `x86_64-linux`.

First, the tarball contains a single top-level `opencode` file and no directory, so nixpkgs' `unpackFile` refuses it ("unpacker appears to have produced no directories") and an explicit `unpackPhase` is required.

Second, the binary's ELF interpreter is `/lib64/ld-linux-x86-64.so.2`, a host path that does not exist inside the build sandbox, so the binary cannot run unless that interpreter is repointed at a store path. The obvious fix is wrong. `autoPatchelfHook` sets the interpreter and reports success, but it also corrupts the executable: the output shrinks by 296 bytes and the command then reports `1.3.14` — its embedded Bun runtime version — instead of the pinned `1.18.33`. A single explicit `patchelf --set-interpreter` grows the binary by one 4 KiB page (normal alignment padding), preserves the correct reported version, and produces a working command. AutoPatchelf's dependency scan and RPATH rewrite are destructive on a Bun single-file executable.

The dangerous property is that the corruption is silent. With no version assertion, the corrupted binary builds cleanly, installs, and only reveals itself as a wrong `--version` string much later. A future maintainer tidying this derivation would reach for `autoPatchelfHook` because it is the conventional Nix answer, and would silently ship a broken agent.

## Decision

For any prebuilt agent binary pinned by this repo, the ELF interpreter SHALL be repointed with a single explicit `patchelf --set-interpreter` call, and automatic ELF dependency rewriting (`autoPatchelfHook` and equivalents) SHALL NOT be used on such binaries.

Such a package SHALL additionally assert its own version at build time, via `doInstallCheck` with `versionCheckHook` and an explicit `versionCheckProgramArg`, so that a build producing a binary which reports the wrong version fails instead of installing.

The `ripgrep` dependency the agent's grep tool needs SHALL be supplied by `makeWrapper --prefix PATH`, matching the wrapping the nixpkgs recipe performed.

## Consequences

- **Easier**: corruption of this class fails the build instead of shipping, so the constraint is enforced by the package rather than by a maintainer remembering it.
- **Easier**: the derivation stays short and readable; there is no nested fixed-output derivation and no `models-dev` hermeticity handling to maintain.
- **Harder**: an unusual amount of ceremony is attached to a package that is, at heart, a downloaded binary. The explicit `unpackPhase` and the `autoPatchelfHook` prohibition need inline comments, or a future maintainer will "simplify" them away.
- **Harder**: the constraint is specific to Bun-style single-file executables. It is not a general rule about patching prebuilt binaries, and it should not be applied to ordinary dynamically linked ELF binaries, where `autoPatchelfHook` remains correct.
- **Follow-up**: if upstream changes its release-asset layout, the `unpackPhase` and the interpreter repoint both need re-verification. The version check will catch a broken result, but not an asset layout that changes in some other way.
