# Concept: Seasonal Outbreaks (Godot)

## Overview
A simulation of seasonal disease outbreaks in a population, modeled in Godot 4.x.

## Core Features
- **Agents**: Patients with SEIR state machine.
- **Facilities**: Hospitals with capacity and queues.
- **Ambulances**: Transport for symptomatic patients.
- **Visuals**: Cute, shape-based aesthetic.
- **UI**: Real-time stats and controls.

## Architecture
- **Engine**: Godot 4.x (GDScript).
- **Simulation**: Tick-based loop in `SimulationEngine`.
- **Validation**: Headless scripts and CI integration.
