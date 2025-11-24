# Seasonal Outbreaks (Godot)

A 2D simulation of seasonal outbreaks using Godot 4.x.

## Features
- **Simulation Engine**: Tick-based simulation of disease spread.
- **Patient Agents**: State machine (Susceptible, Exposed, Infectious, Recovered).
- **Facilities**: Hospitals with capacity and queuing.
- **HUD**: Real-time scoreboard and controls.
- **Logging**: CSV logging of simulation data.

## Setup
1. Open `project.godot` in Godot 4.x.
2. Run the project (F5).

## Mapping to Spec
- **Core Logic**: `scripts/SimulationEngine.gd` (Tick loop, Spawning, Infection Check)
- **Agents**: `scripts/Patient.gd` (FSM: Susceptible, Exposed, Infectious, Recovered)
- **Facilities**: `scripts/Facility.gd` (Capacity, Queue, Service)
- **UI**: `scripts/HUD.gd` (Scoreboard, Scenario Select)
- **Logging**: `scripts/logger.gd` (CSV export to `user://logs/`)
- **Optimization**: `scripts/spatial_grid.gd` (Spatial partitioning for infection checks)
- **Scaling**: `scripts/scale_utils.gd` (Viewport detection and fail-safe constants)

## Scenarios
Presets are located in `scenarios/` and can be loaded via the HUD dropdown:
- `default.json`: Standard parameters.
- `high_density.json`: Higher population, faster spread.

## Known Limitations
- **Visuals**: Placeholder sprites are used.
- **Physics**: Movement is kinematic/transform-based, not physics-based (for performance).
- **Facility Logic**: Service rate is simplified to "chance to discharge" per tick.

See `FEATURES_GODOT_FULL.txt` for full requirements.
