# Tasks

## 1. Pin the opencode package in the Org source

- [ ] 1.1 Resolve the current upstream release of `anomalyco/opencode` and record its version plus the `opencode-linux-x64.tar.gz` asset digest and the SRI hash it converts to, as the initial pin. Reuse the verified values for `v1.18.33` (`sha256-5UYSMhOuR5CaQmhpKqS5SVDQEa/pysmTh1OiGU8cFtU=`) unless upstream has moved on.
- [ ] 1.2 Add an `opencode` package definition to the `dpom-opencode` tangle block in `Config.txt`: pinned `version`, a `pkgs.fetchurl` source with the pinned `hash` and the release-asset URL, and `meta` including `mainProgram`.
- [ ] 1.3 Give the derivation an explicit `unpackPhase` that runs `tar -xzf "$src"`, with a comment recording that the asset is a single top-level file and that `unpackFile` refuses it.
- [ ] 1.4 Set `nativeBuildInputs` to `patchelf`, `makeWrapper`, and `ripgrep`. Confirm `autoPatchelfHook` is absent, and leave a comment stating why (ADR-0007).
- [ ] 1.5 In `installPhase`, install the binary to `$out/bin/opencode`, repoint its interpreter with a single `patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker}` call, then `wrapProgram` it with `--prefix PATH` including `ripgrep`.
- [ ] 1.6 Enable the build-time version assertion: `doInstallCheck = true`, `versionCheckProgramArg = "--version"`, and `versionCheckKeepEnvironment` as needed.
- [ ] 1.7 Assign `programs.opencode.package = opencode` in the module's `config` block, leaving `programs.opencode.enable = true` and the existing `generateOpencodeConfig` wiring unchanged.
- [ ] 1.8 Confirm the `dpom-opencode` module's enable option, generated config, and provider/model definitions are otherwise unchanged.

## 2. Tangle and verify the module builds

- [ ] 2.1 Run `./bin/generate-admin` and confirm `modules/home/opencode.nix` is regenerated and consistent with the updated `Config.txt`.
- [ ] 2.2 Confirm `modules/home/opencode.nix` was not hand-edited, by checking the diff against what the tangle produced.
- [ ] 2.3 Build the package and confirm the install-time version check passes, so the binary reports the pinned version rather than a runtime or Bun version.
- [ ] 2.4 Sanity-check the built command: `opencode --version` reports the pinned version, `opencode debug config` reads the generated configuration, and `rg` resolves on the wrapped `PATH`.
- [ ] 2.5 Run `ent update-home` and confirm the applied `opencode` comes from the module's pin rather than `pkgs.opencode`.
- [ ] 2.6 Confirm the applied version is newer than the version nixpkgs provides, demonstrating the pin actually moves the agent off the nixpkgs version.

## 3. Add the update script

- [ ] 3.1 Write `bin/update-opencode` in babashka, following the structure of `bin/update-ollama`: read the pinned version from the `dpom-opencode` block in `Config.txt`, and exit with a message if it cannot be found.
- [ ] 3.2 Query the GitHub releases API for the latest `anomalyco/opencode` release, validate the tag against the expected `vX.Y.Z` form, and stop without writing if it does not match.
- [ ] 3.3 Implement the already-current path: compare the resolved version to the pinned one, and when equal report that opencode is up to date and exit without modifying any file.
- [ ] 3.4 Locate the `opencode-linux-x64.tar.gz` asset in the release, and stop with a message naming the expected asset if it is absent.
- [ ] 3.5 Derive the source hash from the asset's `digest` field, falling back to downloading the asset and computing the hash when the digest is missing. Convert to SRI with `nix hash convert --to sri`.
- [ ] 3.6 Patch the version and hash into the `dpom-opencode` block in `Config.txt` using block-scoped anchors, and verify the write landed by re-reading the pinned values.
- [ ] 3.7 Re-tangle via `./bin/generate-admin` and confirm `modules/home/opencode.nix` matches the updated source.
- [ ] 3.8 Print the manual next steps: review the diff, apply with `ent update-home`, and commit `Config.txt`, `modules/home/opencode.nix`, and the script together. Do not run `home-manager switch` or any git command from the script.
- [ ] 3.9 Make the script executable.
- [ ] 3.10 Run the script against the current pin and confirm it is a clean no-op that changes no file.

## 4. Exercise the script end to end

- [ ] 4.1 Run the script and confirm it patches a simulated older pin to the current release, including the hash.
- [ ] 4.2 Confirm the patched result is byte-identical to the pin written in task group 1, so the script and the hand-written pin agree.
- [ ] 4.3 Tangle, then build and apply, confirming the resulting `opencode --version` matches the version the script wrote.
- [ ] 4.4 Revert the test bump and re-tangle, restoring the intended pin.
- [ ] 4.5 Exercise the fallback paths: a release with no asset `digest`, and an unexpected tag format. Confirm each stops without modifying any file and reports a clear error.
- [ ] 4.6 Confirm the script leaves no `lib.fakeHash`-style placeholder behind after a successful run.

## 5. Documentation and archive readiness

- [ ] 5.1 Add a short comment header to `bin/update-opencode` describing what it pins, where it reads the pin from, and that it stops before deploying or committing, matching the style of `bin/update-ollama`.
- [ ] 5.2 Confirm the `autoPatchelfHook` prohibition and the reason for it are recorded in the derivation as inline comments, so a future maintainer does not "simplify" them away.
- [ ] 5.3 Decide the open question about shell completions, and record the decision here: either accepted as a known regression or pursued as follow-up work.
- [ ] 5.4 Run `openspec validate update-opencode-agent-version --type change --strict` and confirm it passes.
- [ ] 5.5 Confirm `adr/0006-pin-opencode-to-github-release-binaries.md` and `adr/0007-no-auto-patching-of-prebuilt-agent-binaries.md` reflect the shipped result, especially the baseline-asset open question from ADR-0006, and that neither prior ADR was modified.
- [ ] 5.6 Stage `Config.txt`, `modules/home/opencode.nix`, `bin/update-opencode`, and the two new ADRs together, per the repo's tangle-first commit convention.
