## ADDED Requirements

### Requirement: Markdown Preview SHALL render markdown files with mermaid diagrams
The system SHALL preview the current Markdown buffer as rendered HTML from within Emacs.
Feature: markdown-preview

#### Scenario: Preview renders markdown to HTML in eww
- **GIVEN** a Markdown buffer visiting a `.md` file
- **WHEN** the user invokes the preview command
- **THEN** the buffer content is rendered to HTML via pandoc
- **AND** the HTML is displayed in an eww buffer

#### Scenario: Mermaid code blocks are rendered as SVG
- **GIVEN** a Markdown buffer containing a ````mermaid` code block
- **WHEN** the user invokes the preview command
- **THEN** the mermaid diagram is rendered to SVG via mmdc
- **AND** the SVG is displayed inline in the preview

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
