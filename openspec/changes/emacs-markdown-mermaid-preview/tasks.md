## 1. Emacs Configuration

- [ ] 1.1 Write `local/markdown-preview` function in Emacs.txt that:
      - Creates a temp directory
      - Parses buffer for mermaid code blocks
      - Renders each mermaid block to SVG via mmdc
      - Replaces mermaid blocks with `<img>` tags
      - Pipes modified markdown through pandoc to HTML
      - Opens the HTML file in eww
- [ ] 1.2 Add configuration block in Emacs.txt for the new `local/markdown-preview` bindings
- [ ] 1.3 Bind the preview command in `markdown-mode-map` (consistent with existing `C-c C-p` pattern)

## 2. Verification

- [ ] 2.1 Run `ent generate` to tangle Emacs.txt → init.el
- [ ] 2.2 Run `ent check-emacs` to validate init.el parenthetical balance
- [ ] 2.3 Test preview on a `.md` file with mermaid code blocks

## 3. Change Completion

- [ ] 3.1 Run `openspec validate emacs-markdown-mermaid-preview --type change --strict` before archiving
