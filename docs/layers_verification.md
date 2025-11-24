# Layer Verification

## Collision Layers
- **Manual**: Open `project.godot` -> Layer Names -> 2d_physics. Verify Layer 1=World, 2=Patient, 3=Facility, 4=Vehicle.
- **Programmatic**: Run `misc/validate_layers.gd`. It instantiates scenes and checks `collision_layer` bitmask.

## Visual Layers
- **Manual**: Check `z_index` in Inspector. UI should be highest (CanvasLayer), Vehicles > Patients > World.
- **Programmatic**: (Planned) Script to check `z_index` properties of instantiated nodes.

## Navigation Layers
- **Manual**: Verify `NavigationRegion2D` covers walkable areas.
- **Programmatic**: (Planned) Agent pathfinding test to ensure paths are generated.
