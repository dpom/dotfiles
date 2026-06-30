## Context

The Emacs config already has `markdown-mode`, `mermaid-mode` (previewing `.mmd` files via `mmdc`), and `ob-mermaid` (Org-babel mermaid). Missing: previewing rendered Markdown files containing mermaid code blocks.

pandoc and mermaid-cli (mmdc) are already in `modules/home/emacs/default.nix`. Proposed approach (previously agreed): buffer-local renderer via pandoc, displayed in eww, triggered manually by keybinding.

C4 diagram was considered but deemed unnecessary given the feature's scope (single Elisp function, two CLI tools, one display target).

## Goals / Non-Goals

**Goals:**
- Render the current Markdown buffer to HTML with mermaid code blocks rendered as SVG
- Display the HTML in an eww buffer (side window)
- Triggered manually via a keybinding in `markdown-mode-map`

**Non-Goals:**
- No live/auto-updating preview (manual only)
- No changes to existing `mermaid-mode` or `ob-mermaid` functionality
- No new Nix packages (pandoc, mermaid-cli already present)
- No external browser display

## Decisions

1. **Render pipeline: pre-process mermaid blocks, then pandoc to HTML**
   - Extract each ````mermaid` code block from the buffer, render to SVG via `mmdc`, replace the block with an `<img>` tag pointing to the SVG, then pipe through pandoc for full HTML conversion.
   - *Alternatives considered:* pandoc Lua filter (adds Lua dependency and filter management), grep/sed pipeline (fragile), single mmdc call on full diagram (doesn't handle mixed content). Pre-processing in Elisp keeps everything in one language and gives full control.

2. **Output format: standalone HTML file in system temp dir**
   - Write the final HTML to `(make-temp-file "md-preview-" nil ".html")` and open in eww.
   - *Alternatives considered:* pipe directly to eww via `eww-buffer` with string content — but eww works more reliably with file:// URLs for images.

3. **Display: eww in `display-buffer` side window**
   - Use `(eww-open-file <html-file>)` to display. Let Emacs's `display-buffer` rules decide the window placement (defaults to a side/other window on most configs).
   - *Alternatives considered:* `xwidget-webkit` (not universally available), external browser (leaves Emacs).

4. **Keybinding: `C-c C-p` in markdown-mode-map**, matching the existing mermaid-mode convention.

5. **No C4 diagram** — scope too small to benefit from architectural diagramming.

## Risks / Trade-offs

- **[Performance]** Rendering large mermaid diagrams via mmdc adds latency on each preview. *Mitigation:* synchronous call is fine for manual trigger; user won't invoke it repeatedly.
- **[Temp file cleanup]** SVG and HTML temp files accumulate. *Mitigation:* use `make-temp-file` which registers with Emacs's temp file cleanup; optionally delete on Emacs exit.
- **[mmdc failure]** mmdc may fail on invalid mermaid syntax. *Mitigation:* error handling already exists in `local/mermaid-preview` — reuse same pattern.
- **[eww SVG support]** eww may not render all SVG features. *Mitigation:* mmdc output is simple flat SVGs that eww handles well; test on real-world diagrams.

## Migration Plan

Single commit adding the Emacs Lisp config block to Emacs.txt. No rollout, migration, or rollback needed — purely additive config change.

## Open Questions

- Should the preview command be a custom function under `local/` prefix (like `local/markdown-preview`) or a more generic name?
- Should we reuse the existing `markdown-command` variable or hardcode pandoc?
