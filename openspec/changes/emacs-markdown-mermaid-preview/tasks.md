## 1. Emacs Configuration

- [x] 1.1 Write `local/markdown-preview` function in Emacs.txt that:
      - Creates a temp directory
      - Parses buffer for mermaid code blocks
      - Renders each mermaid block to SVG via mmdc
      - Replaces mermaid blocks with `<img>` tags
      - Pipes modified markdown through pandoc to HTML
      - Opens the HTML file in eww
- [x] 1.2 Add configuration block in Emacs.txt for the new `local/markdown-preview` bindings
- [x] 1.3 Bind the preview command in `markdown-mode-map` (consistent with existing `C-c C-p` pattern)

## 2. Verification

- [x] 2.1 Run `ent generate` to tangle Emacs.txt → init.el
- [x] 2.2 Run `ent check-emacs` to validate init.el parenthetical balance
- [x] 2.3 Test preview on a `.md` file with mermaid code blocks

## 3. Edit Mermaid in Markdown (Org-style C-c ')

- [x] 3.1 Implement `local/markdown-edit-mermaid` command with two-way flow
- [x] 3.2 Bind `C-c '` in markdown-mode-map (opens mermaid block for editing)
- [x] 3.3 Bind `C-c '` in mermaid-mode-map (saves back and closes)

## 4. Verification

- [x] 4.1 Tangle Emacs.txt → init.el
- [x] 4.2 Test edit/save round-trip with multiple mermaid blocks
- [x] 4.3 Test error handling (point not in mermaid block)

## 5. Change Completion

- [x] 5.1 Run `openspec validate emacs-markdown-mermaid-preview --type change --strict` before archiving
