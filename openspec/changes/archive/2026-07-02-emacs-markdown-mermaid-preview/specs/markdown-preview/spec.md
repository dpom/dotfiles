## ADDED Requirements

### Requirement: Markdown Preview SHALL render markdown files with mermaid diagrams
The system SHALL preview the current Markdown buffer as rendered HTML from within Emacs.
Feature: markdown-preview

#### Scenario: Preview renders markdown to HTML in eww
- **GIVEN** a Markdown buffer visiting a `.md` file
- **WHEN** the user invokes the preview command
- **THEN** the buffer content is rendered to HTML via pandoc
- **AND** the HTML is displayed in an eww buffer

#### Scenario: Mermaid code blocks are rendered as PNG
- **GIVEN** a Markdown buffer containing a ````mermaid` code block
- **WHEN** the user invokes the preview command
- **THEN** the mermaid diagram is rendered to PNG via mmdc (with `--scale 2`)
- **AND** the PNG is displayed inline in the preview via an `<img>` tag

#### Scenario: Preview reflects current buffer content
- **GIVEN** a Markdown buffer with unsaved edits
- **WHEN** the user invokes the preview command
- **THEN** the preview reflects the current buffer content (not the saved file)

#### Scenario: mmdc failure shows an error
- **GIVEN** a Markdown buffer with an invalid mermaid diagram
- **WHEN** mmdc fails to render the diagram
- **THEN** the user is shown an error message with mmdc's exit code and stderr

#### Scenario: pandoc failure shows an error
- **GIVEN** a Markdown buffer
- **WHEN** pandoc fails to convert the Markdown to HTML
- **THEN** the user is shown an error message with pandoc's exit code and stderr

### Requirement: Keybinding SHALL invoke the preview command
The preview command SHALL be bound to a key in markdown-mode.

#### Scenario: Preview is bound in markdown-mode-map
- **GIVEN** markdown-mode is active
- **WHEN** the user presses the bound key
- **THEN** the preview command is invoked

#### Scenario: Preview is not bound in other modes
- **GIVEN** a non-markdown buffer (e.g., fundamental-mode)
- **WHEN** the user presses the same key
- **THEN** the default binding for that key is used (no conflict)

### Requirement: Edit-Mermaid SHALL enable two-way editing of mermaid blocks
The system SHALL allow editing mermaid blocks within Markdown buffers via a dedicated mermaid-mode buffer (Org-style `C-c '`).
Feature: markdown-edit-mermaid

#### Scenario: Edit opens mermaid block in mermaid-mode buffer
- **GIVEN** a Markdown buffer with point inside a ````mermaid` code block
- **WHEN** the user invokes the edit-mermaid command (`C-c '`)
- **THEN** a new buffer in `mermaid-mode` is created with the block content
- **AND** the new buffer is displayed in another window

#### Scenario: Edit saves content back to markdown buffer
- **GIVEN** a `mermaid-mode` edit buffer opened via the edit-mermaid command
- **WHEN** the user invokes the edit-mermaid command (`C-c '`) again
- **THEN** the edit buffer content is written back to the parent Markdown buffer
- **AND** the edit buffer is killed
- **AND** focus returns to the parent Markdown buffer

#### Scenario: Edit error if point not in mermaid block
- **GIVEN** a Markdown buffer with point outside any mermaid code block
- **WHEN** the user invokes the edit-mermaid command
- **THEN** the user is shown an error message "Point is not in a mermaid code block"

#### Scenario: Edit error if mermaid block was deleted externally
- **GIVEN** a `mermaid-mode` edit buffer whose parent block was deleted
- **WHEN** saving back
- **THEN** the user is shown an error message that the mermaid block no longer exists
