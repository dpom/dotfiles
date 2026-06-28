## Context

The Emacs configuration already supports diagramming via PlantUML, Graphviz/DOT, and ditaa, all using `org-babel` source blocks. Users write diagram source inline in Org files and render during export. Mermaid.js is a popular diagramming language not yet available in this stack.

The repository uses Nix Flakes with Home Manager. All Emacs config comes from a literate Org file (`Emacs.txt`) which tangles to `init.el`. System packages are declared in `modules/home/emacs/default.nix`.

## Goals / Non-Goals

**Goals:**
- Render Mermaid diagrams from `#+begin_src mermaid` Org blocks via `mermaid-cli` (mmdc)
- Syntax-highlighted editing of `.mmd` files in Emacs
- Preview rendered SVG inline for `.mmd` files via a keybinding
- Match the existing PlantUML workflow pattern (org-babel, SVG output, use-package)
- SVG output format
- All Nix-managed dependencies

**Non-Goals:**
- Live/preview-as-you-type rendering (continuous auto-render on edit)
- Mermaid-specific UI beyond basic editing (helm/company completion, etc.)
- Browser-based Emacs rendering (e.g., xwidget-webkit)

## Decisions

**1. Mermaid CLI (mmdc) as renderer**
  - The standard Mermaid rendering tool, widely adopted, well-documented
  - Alternatives: `mermaid-filter` (pandoc-focused, less Emacs integration), `mmark` (Go-based, less mature)
  - Chosen: mmdc, which `ob-mermaid` expects by default

**2. Puppeteer/Chromium as browser backend**
  - mmdc requires a headless browser; Puppeteer is the default and most compatible
  - On Nix, Chromium is provided via `nodePackages.mermaid-cli` which bundles a chromium dependency
  - Nix ensures reproducible path; no manual `PUPPETEER_CHROMIUM_REVISION` needed when using the Nix package

**3. Emacs packages: `mermaid-mode` + `ob-mermaid`**
  - `mermaid-mode`: syntax highlighting, indentation, and basic navigation for `.mmd` files
  - `ob-mermaid`: org-babel integration (register `mermaid` in `org-babel-load-languages`, render via mmdc)
  - Both from MELPA via `use-package :ensure t`
  - Pattern mirrors the existing `plantuml-mode` + `ob-plantuml` setup exactly

**4. SVG output**
  - mmdc outputs SVG by default; configure `ob-mermaid` to produce SVG inline in Org

**5. Configuration placement**
  - New `use-package` blocks go in `Emacs.txt` under `*** Diagrams`, after the plantuml block (line ~2384)
  - Nix package added to `home.packages` in `modules/home/emacs/default.nix`

**6. `.mmd` file preview in-buffer**
  - `mermaid-mode` does not ship a preview command by default
  - Add a `local/ob-mermaid-preview` command bound to `C-c C-p` in `mermaid-mode-map`
  - Implementation: pipe buffer content to `mmdc -i /dev/stdin -o <temp>.svg`, then display the SVG in a separate buffer via `find-file` or `image-mode`
  - Pattern: similar to `graphviz-dot-mode`'s preview, which uses `graphviz-dot-preview-extension "svg"`

## System Context Diagram

The C4 system context for this integration, lightweight ASCII:

```
+----------+                    +---------------------------+
|  User    | edits Org file     |        Emacs              |
| (Person) | with mermaid src   |  (org-mode + ob-mermaid)  |
|          |------------------>|  (mermaid-mode preview)    |
|          |                   +---------------------------+
|          | edits .mmd file          |         |
|          | and presses C-c C-p     |         | shell-out (mmdc)
|          |------------------------>|         |
+----------+                         |         v
                                     | +------------------+
                                     | |  mermaid-cli     |
                                     | |  (Node.js CLI)   |
                                     | +------------------+
                                     |         |
                                     |         | Puppeteer protocol
                                     |         v
                                     | +------------------+
                                     | |  Chromium        |
                                     | |  (headless)      |
                                     | +------------------+
```

**Boundaries and responsibilities:**
- **User** writes `#+begin_src mermaid ... #+end_src` in Org files and triggers export, or opens a `.mmd` file and invokes preview
- **Emacs** (ob-mermaid) intercepts the mermaid source block, pipes the diagram source to `mmdc`, and inserts the resulting SVG into the Org buffer
- **Emacs** (mermaid-mode with custom preview) writes buffer content to a temp file, runs `mmdc` to produce SVG, and displays it in a preview buffer
- **mermaid-cli** (mmdc) is a Node.js CLI that converts Mermaid text to SVG; it runs Chromium headless via Puppeteer to render the SVG
- **Chromium** does the actual rendering; on Nix it's managed as a build dependency of `nodePackages.mermaid-cli`

**Assumptions:**
- `ob-mermaid` on MELPA works with mmdc out of the box (standard config, no custom wrapper needed)
- mmdc resolves to `~/.nix-profile/bin/mmdc` via Nix (same pattern as plantuml)

## Risks / Trade-offs

- [Size] Chromium adds ~500MB to the Nix closure. Mitigation: this is a one-time cost, and Chromium is already commonly in the Nix store on most systems.
- [Compatibility] `ob-mermaid` may not exist on MELPA or may have a different name. Mitigation: if `ob-mermaid` is unavailable, write a minimal `ob-mermaid` wrapper locally that calls mmdc directly.
- [Nix path] mmdc's Puppeteer may not find the Nix-provided Chromium. Mitigation: the Nix `nodePackages.mermaid-cli` package handles the Chromium path; if issues arise, set `PUPPETEER_CHROMIUM_REVISION` or wrap with a `.puppeteerrc.cjs`.

## Migration Plan

1. Add `nodePackages.mermaid-cli` to `modules/home/emacs/default.nix`
2. Add `use-package` blocks for `mermaid-mode` and `ob-mermaid` in `Emacs.txt`
3. Tangle (`ent generate`)
4. Apply (`home-manager switch`)
5. Test: open a `.mmd` file, verify syntax highlighting, press `C-c C-p`, confirm SVG preview renders
6. Test: open an Org file with `#+begin_src mermaid`, execute block with `C-c C-c`, confirm SVG inline image displays
7. Rollback: revert the Nix package and Emacs config changes, re-tangle, re-apply

## Open Questions

- Does `ob-mermaid` exist on MELPA under that exact name? If not, write a local wrapper.
- Does `nodePackages.mermaid-cli` on nixpkgs 26.05 work correctly out of the box with the Nix Chromium path?
