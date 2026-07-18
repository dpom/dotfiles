## Why

Writing good Git commit messages is tedious and inconsistent. The staged diff contains all the context needed for a meaningful message, but developers often skip it or write low-quality messages. This change integrates gptel with Ollama to generate concise, structured commit messages from staged changes directly in Emacs.

## What Changes

- New Emacs command `local/generate-commit-message` that shells out to `git diff --cached`, sends the diff to gptel (Ollama, `qwen2.5-coder:7b`), and inserts the generated message at point in the current buffer
- New gptel preset `commit-message` with a system prompt tailored for generating conventional commit messages
- Add `("m" "generate message" local/generate-commit-message)` to the existing `local/git-menu` transient

## Capabilities

### New Capabilities
- `commit-message-generation`: Generate a Git commit message from staged changes using gptel + Ollama, inserting it directly into the current buffer

### Modified Capabilities
*(none — this is entirely new functionality)*

## Impact

- **Emacs.txt**: Add the command function, gptel preset, and git-menu entry in their respective Org sections
- **No new dependencies**: gptel, magit, and Ollama are already configured
- **No Nix changes**: The model (`qwen2.5-coder:7b`) is a standard Ollama model — no config changes needed unless we want to pre-load it, which can be a follow-up
