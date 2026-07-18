# commit-message-generation

## Purpose

Generate conventional Git commit messages from staged changes using LLM assistance via gptel. TBD — initial capability definition.

## Requirements

### Requirement: Generate commit message from staged changes
The system SHALL provide an interactive Emacs command `local/generate-commit-message` that generates a Git commit message from staged changes using gptel with Ollama.

Feature: Commit message generation
Rule: The command MUST only operate on staged changes (`git diff --cached`), not unstaged or untracked files.

#### Scenario: Generate message with staged changes in magit commit buffer
- **GIVEN** the user has staged one or more changes in a Git repository
- **GIVEN** the user is in a magit `COMMIT_EDITMSG` buffer
- **WHEN** the user invokes `local/generate-commit-message`
- **THEN** the command SHALL run `git diff --cached` to capture the staged diff
- **THEN** the command SHALL send the diff to gptel with the `commit-message` preset
- **THEN** the command SHALL insert the generated commit message at point in the current buffer

#### Scenario: Generate message from any buffer with staged changes
- **GIVEN** the user has staged changes in a Git repository
- **GIVEN** the user is in any file buffer belonging to that repository
- **WHEN** the user invokes `local/generate-commit-message`
- **THEN** the command SHALL detect the repository root via `locate-dominating-file`
- **THEN** the command SHALL insert the generated message at point

### Requirement: Error handling — no staged changes
The command SHALL signal an error when there are no staged changes.

#### Scenario: No staged changes produces clear error
- **GIVEN** the user is inside a Git repository
- **GIVEN** there are no staged changes (either nothing changed, or changes are unstaged)
- **WHEN** the user invokes `local/generate-commit-message`
- **THEN** the command SHALL call `(user-error "No staged changes to commit")`
- **THEN** no LLM request SHALL be made

### Requirement: Error handling — not in a Git repository
The command SHALL signal an error when called outside a Git repository.

#### Scenario: Outside git repo produces clear error
- **GIVEN** the user is not inside a Git repository
- **WHEN** the user invokes `local/generate-commit-message`
- **THEN** the command SHALL call `(user-error "Not inside a Git repository")`
- **THEN** no LLM request SHALL be made

### Requirement: gptel preset for commit message generation
The system SHALL define a gptel preset named `commit-message` with a system prompt optimized for conventional commit messages.

#### Scenario: Preset uses correct model and system prompt
- **GIVEN** the gptel preset `commit-message` is defined
- **THEN** it SHALL use the `"Ollama"` backend
- **THEN** its model SHALL default to `qwen2.5-coder:7b`
- **THEN** its system prompt SHALL instruct the LLM to generate conventional commit messages (type, scope, subject, body) from a git diff

### Requirement: Integration with git menu
The command SHALL be accessible from the existing `local/git-menu` transient.

#### Scenario: Git menu has generate message entry
- **GIVEN** the `local/git-menu` transient is defined
- **WHEN** the user opens the git menu (`C-x y`)
- **THEN** the menu SHALL display an entry `"m"` labeled "generate message"
- **THEN** pressing `m` SHALL invoke `local/generate-commit-message`
