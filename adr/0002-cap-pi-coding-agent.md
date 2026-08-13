# Cap pi-coding-agent at the Last Hermetically Buildable Version

## Status

Accepted

## Context

`bin/update-pi` pins the pi agent packages in `modules/home/pi.nix` (tangled from `Config.txt`). Upstream `earendil-works/pi` moved the provider model data (`packages/ai/src/providers/data/*.json`) out of the repository: since v0.84.1 the `packages/ai` build runs `npm run generate-models`, which fetches live provider catalogs (`models.dev`, OpenRouter, NVIDIA NIM, etc.) to generate that data before `tsgo` compiles the `providers/*.models.ts` files. A hermetic Nix build (`sandbox = true`, no network) therefore fails with TS2307 on the missing `./data/*.json` modules. v0.80.3 is the last release whose providers do not import the generated data, so the existing module recipe builds it deterministically.

## Decision

Cap `pi-coding-agent` at v0.80.3 in `bin/update-pi` via a per-package "max buildable version" guard. When the latest release exceeds the cap, the script prints a loud skip message and leaves the pin unchanged instead of bumping to an unbuildable version. `pi-acp` is unaffected and keeps tracking latest. The cap is documented in the script header and can be lifted once the pi module recipe is updated to handle upstream's generated data (e.g. vendoring it).

## Consequences

- **Easier**: the repo keeps a buildable pi pin; `update-pi` never silently leaves a pin that breaks the next `home-manager switch`.
- **Easier**: the reason for the cap is visible in the script's output and header, not a silent divergence.
- **Harder**: pi stays at v0.80.3 until someone updates the module recipe — upstream's new build is intentionally non-hermetic, so lifting the cap requires a deliberate follow-up.
- **Follow-up**: either vendor the generated data into the repo and apply it as a build patch, or accept a network-touching (impure) build.
