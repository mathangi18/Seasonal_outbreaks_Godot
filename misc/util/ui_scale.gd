extends Node
# ui_scale.gd — autoload-friendly UI / world scale helper (no class_name)

# Fail-safe constants
const PATIENT_RADIUS := 3.0
const PATIENT_BASE_SPEED := 1.8
const WORLD_W := 600.0
const WORLD_H := 380.0

# Instance fields (autoload will provide global `UIScale`)
var world_width := WORLD_W
var world_height := WORLD_H

func _ready() -> void:
    # Keep world size if project overrides (safe)
    if world_width <= 0.0:
        world_width = WORLD_W
    if world_height <= 0.0:
        world_height = WORLD_H

# screen scale scalar (safe in headless/editor)
func ss() -> float:
    var vp := get_viewport()
    if vp == null:
        return 1.0
    # local names renamed to avoid collision with functions sx()/sy()
    var local_sx: float = float(vp.size.x) / float(world_width)
    var local_sy: float = float(vp.size.y) / float(world_height)
    # clamp and return the minimum scaling factor (safe non-zero)
    return min(max(0.0001, local_sx), max(0.0001, local_sy))

# scale helpers
func sx(v: float) -> float:
    return v * ss()

func sy(v: float) -> float:
    return v * ss()

# convenience: pixel radius for patient
func patient_radius_px() -> float:
    return sx(PATIENT_RADIUS)

# allow runtime override
func set_world_size(w: float, h: float) -> void:
    world_width = max(1.0, w)
    world_height = max(1.0, h)
