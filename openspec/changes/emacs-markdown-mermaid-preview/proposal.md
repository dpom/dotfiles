## Why

Emacs can already preview mermaid diagrams in `.mmd` files and Org-babel blocks, but there's no way to preview rendered Markdown files (`.md`) that contain mermaid code blocks. This makes it hard to write and review documentation with diagrams in Markdown format.

## What Changes

- Add an Emacs command that renders the current Markdown buffer to HTML via pandoc (including mermaid code blocks rendered as SVG via mmdc) and displays the result in an eww buffer
- Bind the command to a key in `markdown-mode-map`
- This is additive — does not modify or break existing mermaid-mode or ob-mermaid functionality

## Capabilities

### New Capabilities
- `markdown-preview`: Render the current Markdown buffer to HTML with mermaid diagrams rendered inline and preview in an eww buffer

### Modified Capabilities

<!-- No existing capabilities are changing — this is purely additive -->

## Impact

- **Emacs config** (`Emacs.txt` / `init.el`): New `use-package` / configuration block for the preview command
- **Dependencies**: `pandoc` and `mermaid-cli` (mmdc) are already in `modules/home/emacs/default.nix` — no package changes needed
- **Keybinding**: Will be bound in `markdown-mode-map` (likely `C-c C-p` consistent with existing mermaid preview)
- **No Nix changes** required (all tools already present)
