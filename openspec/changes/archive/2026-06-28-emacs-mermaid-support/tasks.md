## 1. Nix Dependencies

- [x] 1.1 Add `mermaid-cli` to `home.packages` in `modules/home/emacs/default.nix` (via Config.txt tangle)

## 2. Emacs Configuration

- [x] 2.1 Add `use-package mermaid-mode` block in `Emacs.txt` under `*** Diagrams`, after plantuml block, with `:mode "\\.mmd\\'"` and `C-c C-p` preview keybinding
- [x] 2.2 Add `use-package ob-mermaid` block in `Emacs.txt` under `*** Diagrams`, registering `mermaid` in `org-babel-load-languages`
- [x] 2.3 Add `org-babel-do-load-languages` entry for mermaid in the ob-mermaid `:config`

## 3. Generate and Apply

- [x] 3.1 Tangle `Emacs.txt` → `init.el`
- [x] 3.2 Run `home-manager switch` to apply Nix + Emacs changes

## 4. Verification

- [x] 4.1 Open a `.mmd` file, verify `mermaid-mode` activates with syntax highlighting
- [x] 4.2 Press `C-c C-p` in a `.mmd` buffer with valid content, confirm PNG preview renders
- [x] 4.3 Open an Org file with `#+begin_src mermaid`, execute block with `C-c C-c`, confirm SVG result
- [x] 4.4 Toggle inline image with `C-c C-x C-v` and confirm SVG displays inline

## 5. Validation

- [x] 5.1 Run `openspec validate emacs-mermaid-support --type change --strict`
