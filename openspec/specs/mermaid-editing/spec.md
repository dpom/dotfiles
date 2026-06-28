# mermaid-editing

## Purpose

Provide Mermaid diagram editing support in Emacs with syntax highlighting, indentation, and in-buffer PNG preview for `.mmd` files.

## Requirements

### Requirement: Syntax-highlighted editing
SHALL activate `mermaid-mode` when opening `.mmd` files, providing syntax highlighting and proper indentation

#### Scenario: Open a .mmd file
- **GIVEN** a file with the `.mmd` extension
- **WHEN** the file is opened in Emacs
- **THEN** `mermaid-mode` is activated
- **AND** Mermaid keywords, entities, and relationships are highlighted
- **AND** proper indentation is applied

#### Scenario: Edit Mermaid content
- **GIVEN** a `.mmd` file open in `mermaid-mode`
- **WHEN** the user types Mermaid syntax (e.g., `graph TD; A-->B;`)
- **THEN** syntax highlighting updates in real-time

### Requirement: PNG preview of .mmd files
SHALL provide a `C-c C-p` keybinding in `mermaid-mode` that renders buffer content to PNG via `mmdc`

#### Scenario: Preview a .mmd buffer
- **GIVEN** a `.mmd` buffer with valid Mermaid content
- **WHEN** the user presses `C-c C-p`
- **THEN** the buffer content is piped through `mmdc`
- **AND** the resulting SVG is displayed in a preview buffer
- **AND** the preview buffer opens in `image-mode` or equivalent for inline viewing

#### Scenario: Preview fails on invalid syntax
- **GIVEN** a `.mmd` buffer with invalid Mermaid content
- **WHEN** the user presses `C-c C-p`
- **THEN** an error message is shown in the minibuffer
- **AND** no preview buffer is opened
