## Context

Two AI toolchain applications in this repo need to be kept at their latest releases, but only oh-my-pi has an update script today:

- **Ollama** (`modules/nixos/ollama.nix`, tangled from `Config.txt:1184`) is installed as a NixOS service from `pkgs.ollama.override { acceleration = ... }` — unpinned, it silently tracks the `nixos-26.05` nixpkgs input. `mary` runs it on ROCm; `bob` on CPU.
- **Pi agent** (`modules/home/pi.nix`, tangled from `Config.txt:2575`) pins two npm packages with hardcoded `version`, `rev`, `hash`, and `npmDepsHash`: `pi-coding-agent` (`earendil-works/pi`, v0.80.3) and `pi-acp` (`svkozak/pi-acp`, v0.0.31).

The repo uses literate programming: `Config.txt` is the source of truth; `./bin/generate-admin` tangles it into `.nix` modules. Existing precedent `bin/update-oh-my-pi` sed-edits the tangled `.nix` directly, which diverges from the Org source — this change deliberately does **not** follow that pattern.

**C4-style container diagram (lightweight, assumptions stated):**

```
┌─────────────────────────────┐
│         dan (dev)           │  actor, runs scripts from repo
└─────────────────────────────┘
   │ runs
   ▼
┌──────────────────────┐  ┌──────────────────────┐
│   bin/update-ollama  │  │    bin/update-pi     │  containers (CLI scripts, bash)
└──────────────────────┘  └──────────────────────┘
   │ latest release +       │ latest releases +
   │ fetch amd64(+rocm)     │ prefetch + fake-hash build
   ▼                        ▼
┌────────────────────┐  ┌─────────────────────────┐
│ GitHub API/assets: │  │ GitHub API/assets:      │  external systems
│  ollama/ollama     │  │  earendil-works/pi      │
│                    │  │  svkozak/pi-acp         │
└────────────────────┘  └─────────────────────────┘
   │ update version+hashes          │ update version+hashes
   ▼                                ▼
┌───────────────────────────────────────────────┐
│           Config.txt (Org source)             │  single source of truth
│   #+begin_src nix :tangle modules/nixos/      │
│     ollama.nix  (version, 2 variant hashes)   │
│   #+begin_src nix :tangle modules/home/       │
│     pi.nix  (2× version/hash/npmDepsHash)     │
└───────────────────────────────────────────────┘
   │ ./bin/generate-admin (tangle)
   ▼
┌────────────────────────┐  ┌───────────────────┐
│ modules/nixos/ollama.nix │  │ modules/home/pi.nix │  generated outputs
└────────────────────────┘  └───────────────────┘
```

Assumptions: purpose = design of a new system; format = ASCII; rigor = lightweight C4-inspired (container level only; components are trivial bash). Git commit + host activation are out of scope for the scripts.

## Goals / Non-Goals

**Goals:**
- `bin/update-ollama` and `bin/update-pi` bring their applications to the latest GitHub release.
- Scripts edit the **Org source** (`Config.txt`) and re-tangle, keeping generated `.nix` files in sync with the source of truth (AGENTS.md convention).
- Deterministic hashing: source hashes computed from the actual release artifacts; `npmDepsHash` discovered by a real fetch.
- Idempotent: "already up to date" when pinned version equals latest; no file changes.
- No new runtime dependencies beyond what the repo already uses (`curl`, `jq`, `nix`, git).
- Stop after updating files — no `home-manager switch` / `nixos-rebuild`, no git commit, no push.

**Non-Goals:**
- Not fixing `bin/update-oh-my-pi`'s divergence from `Config.txt` (flagged as open question).
- Not automating pi's `models.json` config generation or model lists.
- Not updating the `nixpkgs` flake input (ollama no longer tracks nixpkgs once pinned).
- Not adding CI, scheduling, or cross-host orchestration.

## Decisions

### 1. Ollama: pin via prebuilt release binaries (oh-my-pi pattern), not a source rebuild

`modules/nixos/ollama.nix` gains a versioned derivation that fetches the **prebuilt** GitHub release asset and installs it as `bin/ollama`:

- CPU host (bob, `acceleration = null`): asset `ollama-linux-amd64`.
- ROCm host (mary, `acceleration = "rocm"`): asset `ollama-linux-amd64-rocm`.

Both variant hashes are pinned in the module; the existing `dpom-ollama.acceleration` option selects the variant. `services.ollama.package` points at the selected derivation. The update script downloads **both** assets, computes both SRI hashes, and updates version + both hashes.

*Why over `pkgs.ollama.overrideAttrs { version = ...; src = fetchFromGitHub { ... }; }`:*
- Matches the user's explicit "like update-oh-my-pi" direction.
- Delivers the exact latest release without waiting on nixpkgs packaging or running a long Go/ROCm source build on every bump.
- Hash is a plain `curl` + `sha256sum` + `nix hash convert --to sri` — the same deterministic, self-contained approach as `update-oh-my-pi`.

*Alternative considered:* `overrideAttrs` source build — preserves nixpkgs' build logic and its ROCm integration, and needs only one source-tarball hash. Rejected as primary: slower, couples the pinned version to nixpkgs' (older) Go/module setup, and still requires a real build to validate. Kept as a fallback if the prebuilt ROCm binary has runtime issues on `mary` (see Risks).

### 2. Pi: source hash via `nix-prefetch-url --unpack`, `npmDepsHash` via fake-hash build

`pkgs.fetchFromGitHub` in `pi.nix` hashes the GitHub **archive tarball**, so the script computes it with:

```sh
nix-prefetch-url --unpack "https://github.com/<owner>/<repo>/archive/refs/tags/v${VERSION}.tar.gz"
nix hash convert --to sri "sha256:$RAW"
```

For `npmDepsHash` (a fetch of the npm dependency tree, not derivable from the tarball), the script uses the standard nix technique:

1. Temporarily set `npmDepsHash` to `lib.fakeHash` in the Org block.
2. Tangle, then attempt the relevant derivation build (`nix build` of the home config / package).
3. Parse the real hash from the build error (`got:    sha256-...`).
4. Write it back and re-tangle.

*Why `nix-prefetch-url --unpack` over `nix-prefetch-git`:* `fetchFromGitHub`'s `hash` field matches the tarball hash, not the git hash. The tarball URL mirrors what the flake pin `rev = "v${version}"` resolves to.

### 3. Edit `Config.txt` (Org source), then tangle — not the `.nix`

Both scripts rewrite their target Org block in `Config.txt` with block-scoped, multi-line `sed` anchors (e.g. matching `version` together with the following `owner`/`repo` lines, or `pname = "pi-acp";` + `version`), so the same literal strings elsewhere in the file (other `version = "..."` / `hash = "..."` lines) are never touched. After editing, the scripts run `./bin/generate-admin` to re-tangle, so `modules/nixos/ollama.nix` and `modules/home/pi.nix` reflect the source.

*Why not sed the `.nix` directly (current `update-oh-my-pi` behavior):* it diverges from the source of truth and is silently reverted on the next tangle. Per user decision + AGENTS.md.

### 4. Script conventions

Bash, `set -euo pipefail`, `cd` to repo root via `readlink -f` (same skeleton as `bin/update-oh-my-pi`). Steps in order: resolve latest tag (GitHub `/releases/latest`); compare to pinned version → exit early if equal; fetch/derive hashes; patch `Config.txt`; tangle; print summary + next steps (`ent home-update` / `ent update-system` / commit). No new packages required at runtime.

### 5. Pi updates both packages in one run

One script resolves `earendil-works/pi` **and** `svkozak/pi-acp` latest tags independently and updates each block. Rationale: both are "the pi agent"; a single entry point keeps the workflow obvious. Alternative (two scripts) rejected as over-fragmented.

## Risks / Trade-offs

- **Prebuilt ROCm binary may need system ROCm libs on `mary`** → Mitigation: existing module already installs `rocmPackages.clr.icd` / `rocmPackages.clr` / `rocmPackages.rocminfo`; verify `ollama` starts under the service during implementation; fall back to the `overrideAttrs` source build (Decision 1) if the binary misbehaves — the script's interface is unchanged either way.
- **sed anchor drift in `Config.txt`** → Mitigation: multi-line context anchors; scripts grep-verify the patched block and diff the tangled output before finishing.
- **`npmDepsHash` discovery is slow / fails** (full eval + dependency fetch) → Mitigation: per-package run, robust parse of `got:`; print the hash on failure with a manual-edit fallback.
- **GitHub API rate limiting / tag format drift** (tags not `vX.Y.Z`) → Mitigation: scripts fail loudly with the raw tag when the pattern doesn't match; never silently no-op on a parse miss.
- **Pinned ollama no longer tracks nixpkgs security fixes** → Mitigation: the update script is the mechanism to stay current; no extra action beyond running it.

## Migration Plan

1. Restructure the ollama module block in `Config.txt` to add the versioned binary derivations + variant hashes (CPU + ROCm), keeping `services.ollama` options/`environmentVariables` unchanged. Tangle and confirm the service still activates on both hosts (`nix build .#nixosConfigurations.mary.config.system.build.toplevel` — no switch).
2. Write `bin/update-ollama`; run against the current pinned version to confirm idempotent "already up to date" path.
3. Write `bin/update-pi`; test the fake-hash `npmDepsHash` discovery against a current pinned package (dry, no bump) to validate hash round-trip.
4. Review `git diff` of `Config.txt` + tangled outputs; commit source and generated files together.

Rollback: plain `git revert` — scripts make file changes only, so a revert restores the previous pin; no service rollback step is needed.

## Open Questions

- **`bin/update-oh-my-pi`**: migrate it to the same Config.txt-editing approach in this change, or leave as-is (its edit currently diverges from the Org source until a manual re-tangle)? Defaulting to **leave as-is**; separate follow-up change if wanted.
- **ROCm runtime**: does `ollama-linux-amd64-rocm` run correctly with the module's existing ROCm packages and env vars on `mary`? To be verified during implementation; fallback documented in Decision 1.
- **Ollama asset naming drift**: if upstream changes asset names (e.g. `ollama-linux-amd64-rocm` → versioned suffix), the script needs a small update — accepted, documented in the script header.

No in-force ADRs exist (`adr/` is empty), so no supersession is triggered by these decisions.
