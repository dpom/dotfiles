# Pin opencode to Prebuilt GitHub Release Assets, Including Shell Completions

## Status

accepted, supersedes ADR-0006

## Date

2026-09-30

Supersedes: ADR-0006

## Context

ADR-0006 pinned the opencode agent to a prebuilt `anomalyco/opencode` release asset and delegated to `bin/update-opencode` for bumps. That decision holds. Two of its recorded consequences did not, and both are corrected here.

**Shell completions were recorded as an accepted regression, on a misdiagnosis.** ADR-0006 claimed `opencode completion` failed in the build sandbox "apparently due to the SQLite database migration that runs at opencode startup", and listed `writableTmpDirAsHomeHook` among mitigations that "did not resolve it". There is no SQLite involvement, and the hook is part of the fix. Re-running the completion command in a real sandbox produced the actual error:

```
EEXIST: file already exists, mkdir '/build/opencode'
    syscall: "mkdir",  errno: -17,  code: "EEXIST"
```

The cause is a filename/directory collision. `$TMPDIR` during a Nix build is the build directory, `/build`. The derivation unpacked the asset's single top-level file to `/build/opencode` as a *file*, while opencode creates `$TMPDIR/opencode` as a cache *directory*; `mkdir` on the existing file failed and the process died before printing anything. Unpacking into a subdirectory, plus `writableTmpDirAsHomeHook` for the `mkdir '/homeless-shelter'` `EACCES` seen without it, produces completions.

The earlier mitigation testing was itself misleading: `writableTmpDirAsHomeHook` was trialed in the same iteration that set `XDG_DATA_HOME` and friends to relative paths, and the *XDG* change is what kept failing. The failure was attributed to the hook. A useful signal was available and not followed up: `opencode completion` worked outside the sandbox, which should have ruled out any incompatibility in the binary.

The reason this hid so well is that `--version` short-circuits before opencode initialises its data directory, so `versionCheckHook` passed throughout. The only visible symptom was missing shell completions, with no error surfaced to explain them.

**The asset-to-CPU follow-up is now resolved.** ADR-0006 asked that the asset-to-CPU mapping not be assumed, because the non-baseline asset's runtime self-identified as a baseline build. Confirmed: `opencode-linux-x64.tar.gz` is compiled against Bun's `bun-linux-x64-baseline` target, with the download URL and the banner `Bun v1.3.14 (Linux x64 baseline)` both baked into the binary. The name and the actual ISA target genuinely disagree.

mary is unaffected either way. Its CPU (AMD Ryzen AI 9 HX 370) reports `avx2` and `avx512f`, and a baseline-targeted binary is the more conservative of the two, running on essentially any x86-64 host. The pinned build also passes its install check on this host, which demonstrates it directly. A separate `opencode-linux-x64-baseline.tar.gz` is published (1 byte larger, different digest); what ISA target *it* uses was not verified and is left open below.

## Decision

The pin itself is unchanged: `dpom-opencode` defines an `opencode` package pinned to an exact `anomalyco/opencode` release, and `bin/update-opencode` drives bumps from the release API.

Two corrections to the recipe:

- The release asset SHALL be unpacked into a subdirectory, not the build root, so that no file named `opencode` sits in `$TMPDIR` where opencode's own cache directory would collide with it. This is a correctness requirement, not a style preference, and the reason is not obvious from the failure.
- The derivation SHALL install shell completions generated from the binary, as the nixpkgs recipe did, using `writableTmpDirAsHomeHook` to give opencode a writable `HOME` in the sandbox.

ADR-0007 is unaffected and remains in force: automatic ELF dependency rewriting is still forbidden for this binary, and the build-time version check is still what enforces it. Note that the two requirements are independent — the version check cannot detect a completion failure, and the completion step cannot detect a corrupted binary.

## Consequences

- **Easier**: the pinned package regains parity with the nixpkgs build it replaces. Both `share/bash-completion/completions/opencode.bash` and `share/zsh/site-functions/_opencode` are installed, and the bash completion registers as `complete -F _opencode_yargs_completions opencode`. There is no longer a functional regression to accept.
- **Easier**: the build now fails loudly if completions break, because `installShellCompletion` errors on an empty or missing file. A silent loss of completions, which is what the collision caused, can no longer pass unnoticed.
- **Harder**: the unpack-into-a-subdirectory step looks like pointless ceremony and invites "simplification" back to the build root, which would silently remove all shell completions while leaving every other check green. The inline comment in the derivation says why, and should be treated as load-bearing.
- **Harder**: `writableTmpDirAsHomeHook` is now required for reasons unrelated to its usual purpose, which is not obvious from reading `nativeBuildInputs`.
- **Unchanged**: the loss of `share/opencode/{config,tui}.json` JSON schemas stands. It comes from `packages/opencode/script/schema.ts` in the source tree and is not in the release asset, so a prebuilt-asset pin cannot provide it. Runtime behavior is unaffected because the opencode configuration is generated separately; editor-side JSON schema validation of `opencode.json` is still lost.
- **Follow-up**: if a host with a pre-AVX2 CPU is ever added, confirm its requirements before assuming the pinned asset is adequate. The pattern to follow is the per-variant option already used for ollama's `acceleration` option in `modules/nixos/ollama.nix`. The ISA target of the separate `opencode-linux-x64-baseline.tar.gz` asset is unverified and would be worth checking if that variant is ever adopted.
