## Why

Enable rendering and editing of Mermaid diagrams within Emacs — matching the existing PlantUML workflow with `org-babel` source block support, syntax-highlighted editing of `.mmd` files, and SVG export via `mermaid-cli`.

## What Changes

- Add `nodePackages.mermaid-cli` to Home Manager packages (system-level Nix package)
- Configure Puppeteer/Chromium path for `mmdc` on Nix
- Add `mermaid-mode` for editing `.mmd` files (syntax highlighting, keybindings)
- Add `ob-mermaid` for org-babel `#+begin_src mermaid` blocks
- Register `mermaid` in `org-babel-load-languages` under the existing `*** Diagrams` heading
- Configure `ob-mermaid` to render to SVG via `mmdc`, mirroring the PlantUML integration pattern

## Capabilities

### New Capabilities
- `mermaid-editing`: Syntax-highlighted editing of Mermaid diagram files (`.mmd`) in Emacs with `mermaid-mode`
- `mermaid-org-babel`: Org-babel source block integration (`#+begin_src mermaid`) that renders diagrams to SVG via `mermaid-cli` during export and preview

### Modified Capabilities
- (none)

## Impact

- **`modules/home/emacs/default.nix`**: Add `nodePackages.mermaid-cli` to `home.packages`
- **`Emacs.txt`** (literate source for `init.el`): Add `use-package` blocks for `mermaid-mode` and `ob-mermaid` under the `*** Diagrams` heading, after the existing PlantUML configuration
- **Nix closure**: Adds Chromium (~500MB) as a transitive dependency via Puppeteer
- **No breaking changes** to existing diagram workflows (PlantUML, Graphviz, ditaa remain untouched)
