## Context

The Emacs config already has `markdown-mode`, `mermaid-mode` (previewing `.mmd` files via `mmdc`), and `ob-mermaid` (Org-babel mermaid). Missing: previewing rendered Markdown files containing mermaid code blocks, and editing mermaid blocks within Markdown files.

pandoc and mermaid-cli (mmdc) are already in `modules/home/emacs/default.nix`. Approach (implemented): buffer-local renderer via pandoc, mermaid blocks rendered to PNG via mmdc, displayed in eww, triggered manually by keybinding. Plus an Org-style `C-c '` flow for editing mermaid blocks.

## Goals / Non-Goals

**Goals:**
- Render the current Markdown buffer to HTML with mermaid code blocks rendered as PNG via mmdc
- Display the HTML in an eww buffer (side window)
- Triggered manually via `C-c C-p` in `markdown-mode-map`
- Edit mermaid code blocks in a dedicated `mermaid-mode` buffer with `C-c '`

**Non-Goals:**
- No live/auto-updating preview (manual only)
- No changes to existing `mermaid-mode` or `ob-mermaid` functionality
- No new Nix packages (pandoc, mermaid-cli already present)
- No external browser display

## Decisions

1. **Render pipeline: pre-process mermaid blocks to PNG, then pandoc to HTML**
   - Extract each ````mermaid` code block from the buffer, render to **PNG** via `mmdc` (with `--scale 2` for HiDPI support), replace the block with an `<img>` tag pointing to the PNG, then pipe through pandoc for full HTML conversion.
   - *Alternatives considered:* SVG output (larger file size, inconsistent eww rendering), pandoc Lua filter (adds Lua dependency and filter management), grep/sed pipeline (fragile). Pre-processing in Elisp keeps everything in one language and gives full control.

2. **Output format: standalone HTML + intermediate files in temp directory**
   - Create a temp directory via `(make-temp-file "md-preview-" t)`, write the buffer content as `content.md`, process mermaid blocks in-place, then run pandoc to produce `preview.html` in the same directory. Open with `(eww-open-file html-file)`.
   - *Alternatives considered:* single temp HTML file (images need adjacent directory anyway), pipe directly to eww via `eww-buffer` (eww works more reliably with file:// URLs for images).

3. **Display: eww via `eww-open-file`**
   - Use `(eww-open-file <html-file>)` to display. Let Emacs's `display-buffer` rules decide the window placement.

4. **Keybindings: `C-c C-p` for preview, `C-c '` for edit-mermaid** in markdown-mode-map, matching existing mermaid-mode and Org conventions respectively.

5. **Edit-mermaid flow**: Two-way round-trip — `C-c '` in markdown-mode opens the mermaid block in a new `mermaid-mode` buffer; `C-c '` in that edit buffer saves content back to the parent Markdown buffer and closes.

6. **Transient menus**: Both `local/mermaid-menu` and `local/markdown-menu` updated with entries for the new commands (edit mermaid block, preview).

7. **No C4 diagram** — scope too small to benefit from architectural diagramming.

## Risks / Trade-offs

- **[Performance]** Rendering mermaid diagrams via mmdc adds latency on each preview. *Mitigation:* synchronous call is fine for manual trigger; user won't invoke it repeatedly.
- **[Temp file cleanup]** PNG and HTML temp files accumulate. *Mitigation:* use `make-temp-file` which registers with Emacs's temp file cleanup; optionally delete on Emacs exit.
- **[mmdc failure]** mmdc may fail on invalid mermaid syntax. *Mitigation:* error handling checks exit code and stderr, providing clear error messages.
- **[eww PNG support]** eww handles PNG reliably across all backends, unlike SVG.

## Migration Plan

Single commit adding the Emacs Lisp config block to Emacs.txt. No rollout, migration, or rollback needed — purely additive config change.

## Open Questions

Resolved during implementation:
- Naming: `local/markdown-preview` and `local/markdown-edit-mermaid` under `local/` prefix, consistent with existing convention.
- Pandoc use: hardcoded in `local/markdown-preview`; `markdown-command` is separately set to `"marked"` for markdown-mode's own preview.
