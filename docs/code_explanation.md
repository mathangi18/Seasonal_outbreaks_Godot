# Code Explanation

## scripts/SimulationEngine.gd
- `spawn_patients()`: Instantiates patients.
- `_on_tick()`: Main loop. Updates agents, checks infections, dispatches ambulances.

## scripts/Patient.gd
- `sim_tick()`: Updates state timers.
- `_physics_process()`: Handles movement.

## scripts/Facility.gd
- `admit()`: Adds to occupants or queue.
- `tick_service()`: Processes discharges and queue.

## scripts/Ambulance.gd
- `dispatch()`: Assigns target.
- `_physics_process()`: State machine for movement/transport.
