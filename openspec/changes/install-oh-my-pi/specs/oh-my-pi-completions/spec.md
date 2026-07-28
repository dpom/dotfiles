## ADDED Requirements

### Requirement: Shell completions for bash
Feature: oh-my-pi-completions
Rule: The module SHALL add oh-my-pi bash completions to `~/.bashrc` automatically.

#### Scenario: Bash completions loaded
- **GIVEN** `dpom-oh-my-pi.enable = true`
- **WHEN** the user opens a new bash shell
- **THEN** `~/.bashrc` SHALL contain `eval "$(omp completions bash)"`
- **THEN** typing `omp ` followed by Tab SHALL show completions

### Requirement: Shell completions for zsh
Feature: oh-my-pi-completions
Rule: The module SHALL add oh-my-pi zsh completions to `~/.zshrc` automatically.

#### Scenario: Zsh completions loaded
- **GIVEN** `dpom-oh-my-pi.enable = true`
- **WHEN** the user opens a new zsh shell
- **THEN** `~/.zshrc` SHALL contain `eval "$(omp completions zsh)"`
- **THEN** typing `omp ` followed by Tab SHALL show completions

### Requirement: Shell completions for fish
Feature: oh-my-pi-completions
Rule: The module SHALL generate fish completions at `~/.config/fish/completions/omp.fish`.

#### Scenario: Fish completions available
- **GIVEN** `dpom-oh-my-pi.enable = true`
- **WHEN** `home-manager switch` runs
- **THEN** `~/.config/fish/completions/omp.fish` SHALL be created
- **THEN** typing `omp ` followed by Tab in fish SHALL show completions

### Requirement: Completions are generated at activation
Feature: oh-my-pi-completions
Rule: Shell completions SHALL be generated during `home-manager switch`, not at build time.

#### Scenario: Completions generated at activation
- **GIVEN** `dpom-oh-my-pi.enable = true`
- **WHEN** `home-manager switch` runs
- **THEN** the activation hook SHALL run `omp completions bash` and append to `~/.bashrc`
- **THEN** the activation hook SHALL run `omp completions zsh` and append to `~/.zshrc`
- **THEN** the activation hook SHALL run `omp completions fish` to `~/.config/fish/completions/omp.fish`

#### Scenario: Completions not duplicated
- **GIVEN** `dpom-oh-my-pi.enable = true`
- **WHEN** `home-manager switch` runs multiple times
- **THEN** the completion lines SHALL NOT be duplicated in `~/.bashrc` or `~/.zshrc`
