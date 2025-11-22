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
- **Core Logic**: `scripts/SimulationEngine.gd`
- **Agents**: `scripts/Patient.gd`
- **Facilities**: `scripts/Facility.gd`
- **UI**: `scripts/HUD.gd`
- **Logging**: `scripts/logger.gd`

See `FEATURES_GODOT_FULL.txt` for full requirements.
