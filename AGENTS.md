# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Tech stack and runtime entrypoints
- Engine: **Godot 4.6** (`Forward Plus` renderer, `Jolt Physics`) configured in `project.godot`.
- Main entry scene: `scenes/menu/intro_cubyt.tscn` (set in `project.godot`).
- Main flow:
  1. `intro_cubyt.tscn` (intro splash)
  2. `menu_principal.tscn`
  3. gameplay transition to `levels/AreaBase/AreaBase.tscn` (currently referenced from menu script)

## Common development commands
Use `godot` as the CLI binary in this repo.

- Open editor for normal development:
  - `godot --path .`
- Run the project from CLI:
  - `godot --path .`
- Reimport/check resource integrity headlessly (closest thing to a build/lint pass in current setup):
  - `godot --headless --path . --import --quit`
- Run the repo’s scripted interaction test:
  - `godot --headless --path . --script scripts/components/test_interaccion.gd`

Notes:
- There is no dedicated lint pipeline (no configured `gdlint`/`gdformat`/CI lint script found).
- There is no formal multi-test framework configured; `test_interaccion.gd` is an ad-hoc SceneTree test script.

## Architecture (high-level)
### 1) Global game state is singleton-driven
Autoloads in `project.godot` are the backbone of runtime behavior:
- `scripts/autoloads/gestor_gameplay.gd`: in-game clock, shop open/close rules, customer eligibility windows.
- `scripts/autoloads/gestor_visitantes.gd`: visitor spawn orchestration, route generation, archetype distribution.
- `scripts/autoloads/gestor_menus.gd`: global menu lock/unlock of player controls.
- `scripts/autoloads/gestor_inventario.gd`: equipped item state + hit detection flow.
- `scripts/autoloads/sistema_nombre_cine.gd` + `gestor_inicio.gd`: first-run naming flow persisted to `user://nombre_cine.save`.
- `scenes/ui/transicion.tscn` (`Transicion` autoload): scene transition wrapper used by menu flow.

### 2) World assembly is scene-composition based
- `levels/AreaBase/AreaBase.tscn` is the world composition root used by the Play button.
- It instances:
  - environment/exterior shells (`scenes/exterior/*`)
  - area modules (`levels/AreaBase/modules/*`)
  - gameplay root (`scenes/jugabilidad/sistema_jugabilidad.tscn`)
  - player (`scenes/personaje/personaje.tscn`)
  - UI (`scenes/ui/hud.tscn`)
- `scenes/jugabilidad/sistema_jugabilidad.tscn` hosts queue logic, visitor marker points, and interactive systems.

### 3) Interaction pipeline is HUD raycast + groups
- HUD script performs center-screen raycast and identifies interactables via:
  - `interactuable` group
  - explicit interaction methods
  - fallback name heuristics
- Interactive props (e.g. store switch, doors, displays) mostly live in `scripts/components/*` and depend on HUD “looking at object” checks plus distance gates.

### 4) NPC/queue/cinema behavior is route and seat assignment driven
- `Visitante` (in `scripts/components/visitante.gd`) is a stateful CharacterBody3D with archetypes/states.
- `GestorVisitantes` builds routes from marker categories (`PuntoVisitante`) and assigns lounge/queue/cinema behavior.
- `SistemaFila` controls front-of-line interaction and handoff to cinema seating logic.
- `SalaCine`/seat utility scripts handle seat assignment and sitting poses.

## Important repository-specific caveat
This repo is in a **partially migrated structure state**:
- New directories exist (`scripts/autoloads`, `scripts/components`, `scripts/gameplay`, `scripts/ui`, `scenes/levels`, `scenes/salas`, `assets/*`).
- Many scenes/scripts still reference legacy paths such as:
  - `res://scripts/...`
  - `res://levels/...`
  - `res://fonts/...`

When editing references, verify both old and new trees before assuming a path is obsolete. Prioritize whatever is actually loaded by:
1. `project.godot` autoload/main scene config
2. currently linked `.tscn` ext_resource paths
3. runtime transition targets in menu scripts

## Key directories to orient quickly
- `scenes/menu/`: intro + main menu flow.
- `levels/AreaBase/`: actively used gameplay world root and module composition.
- `scenes/decoraciones/`: reusable prop wrappers and decorative scene instances.
- `scripts/autoloads/`: global systems/state.
- `scripts/components/`: gameplay entities and interactables.
- `scripts/gameplay/`: time/day-night cycle.
- `scenes/ui/` + `scripts/ui/`: HUD and UI scene logic.
- `docs/`: design docs (including ongoing structure reorganization notes).
