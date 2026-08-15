# Delta Spec: pi-agent-update-script

## ADDED Requirements

### Requirement: Bumped pi-coding-agent pin is buildable
Feature: pi-agent-update-script
Rule: When `bin/update-pi` raises the `pi-coding-agent` pin to a newer `earendil-works/pi` release, the regenerated module SHALL build hermetically without manual recipe edits, including compiling the `telemetry` workspace before `ai`.

#### Scenario: Updated pin builds with ent update-home
- **GIVEN** a newer `earendil-works/pi` release exists than the currently pinned version
- **WHEN** `bin/update-pi` resolves it, updates the pins in `Config.txt`, hydrates the model data, discovers `npmDepsHash`, and re-tangles
- **THEN** `modules/home/pi.nix` SHALL pin the resolved version with matching source hash and `npmDepsHash`
- **THEN** `modules/home/pi-model-data/<version>/` SHALL contain the hydrated snapshot for the resolved version
- **THEN** `ent update-home` SHALL build the `pi-coding-agent` package successfully without manual hash or recipe edits
