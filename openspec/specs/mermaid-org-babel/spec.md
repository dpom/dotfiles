# mermaid-org-babel

## Purpose

Enable Mermaid diagram rendering within Org-mode documents via `#+begin_src mermaid` blocks, using `ob-mermaid` and `mermaid-cli` (mmdc) for SVG output.

## Requirements

### Requirement: org-babel mermaid source blocks
SHALL execute `#+begin_src mermaid` blocks and render them to SVG via `ob-mermaid` and `mmdc`

#### Scenario: Execute a mermaid source block
- **GIVEN** an Org file with a `#+begin_src mermaid ... #+end_src` block containing valid Mermaid diagram source
- **WHEN** the user executes the block with `C-c C-c`
- **THEN** the block is processed by `ob-mermaid`
- **AND** `mmdc` is invoked to render the diagram
- **AND** the resulting SVG is inserted as the block result

#### Scenario: Toggle inline image display
- **GIVEN** an Org buffer with an executed `#+begin_src mermaid` block whose result is an SVG
- **WHEN** the user presses `C-c C-x C-v`
- **THEN** the SVG is displayed inline in the Org buffer
- **AND** the user can visually inspect the rendered diagram

#### Scenario: Export to HTML
- **GIVEN** an Org file containing `#+begin_src mermaid` blocks with valid diagram source
- **WHEN** the user exports the file to HTML
- **THEN** each mermaid source block is rendered to SVG
- **AND** the SVG images are embedded in the exported HTML output

### Requirement: SVG output format
SHALL produce SVG output for all mermaid source block rendering

#### Scenario: Render to SVG by default
- **GIVEN** a mermaid source block is executed or a `.mmd` file is previewed
- **WHEN** `mmdc` renders the diagram
- **THEN** the output format is SVG
- **AND** the SVG is scalable and can be resized without loss
