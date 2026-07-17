## 1. Add gptel preset for commit message generation

- [ ] 1.1 Add the `commit-message` gptel preset to the gptel presets section of Emacs.txt (near line 3390), using `qwen2.5-coder:7b` model and a system prompt for conventional commit messages

## 2. Add interactive command

- [ ] 2.1 Add `local/generate-commit-message` command to Emacs.txt, following the `gptel-request` pattern from `local/translate` and `local/review-elisp`, with:
  - `git diff --cached --staged` shellout
  - Error handling for "not a git repo" and "no staged changes"
  - gptel-request with the `commit-message` preset
  - Insert result at point in current buffer

## 3. Integrate with git menu

- [ ] 3.1 Add `("m" "generate message" local/generate-commit-message)` to the `local/git-menu` transient definition

## 4. Tangling and verification

- [ ] 4.1 Run `ent generate` to tangle Emacs.txt
- [ ] 4.2 Run `ent check-emacs` to validate the generated config
- [ ] 4.3 Pull the model: `ollama pull qwen2.5-coder:7b`
