## Why

Emacs can already preview mermaid diagrams in `.mmd` files and Org-babel blocks, but there's no way to preview rendered Markdown files (`.md`) that contain mermaid code blocks. This makes it hard to write and review documentation with diagrams in Markdown format.

## What Changes

- Add an Emacs command that renders the current Markdown buffer to HTML via pandoc (including mermaid code blocks rendered as PNG via mmdc) and displays the result in an eww buffer
- Bind the preview command to `C-c C-p` and the edit-mermaid command to `C-c '` in `markdown-mode-map`
- This is additive — does not modify or break existing mermaid-mode or ob-mermaid functionality

## Capabilities

### New Capabilities
- `markdown-preview`: Render the current Markdown buffer to HTML with mermaid diagrams rendered inline (as PNG via mmdc) and preview in an eww buffer
- `markdown-edit-mermaid`: Edit a mermaid code block in a Markdown buffer inside a dedicated `mermaid-mode` buffer, with two-way save (Org-style `C-c '`)

### Modified Capabilities

<!-- No existing capabilities are changing — this is purely additive -->

## Impact

- **Emacs config** (`Emacs.txt` / `init.el`): New `use-package` / configuration block for the preview command and mermaid-edit function
- **Dependencies**: `pandoc` and `mermaid-cli` (mmdc) are already in `modules/home/emacs/default.nix` — no package changes needed
- **Keybindings**: `C-c C-p` for preview and `C-c '` for edit-mermaid in `markdown-mode-map`
- **No Nix changes** required (all tools already present)
