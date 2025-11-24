# Quick Test Guide

## Validation Checklist

- [ ] **Project Loads**: No missing resource errors on startup.
- [ ] **Simulation Starts**: Patients spawn and move.
- [ ] **Infection Spreads**: Patients change color (Green -> Yellow -> Red -> Blue).
- [ ] **Scoreboard Updates**: Counts change in the HUD.
- [ ] **Logging Works**: `user://logs/sim_log.csv` is created.
- [ ] **Fail-safe**: Simulation runs even if viewport detection fails (fallback constants).

## Troubleshooting
- If patients don't move, check `scale_utils.gd` logic.
- If logging fails, check write permissions for `user://`.
