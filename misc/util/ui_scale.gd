# res://misc/util/ui_scale.gd
# Minimal autoload-friendly UIScale helper (no class_name to avoid hiding autoload)
extends Node

# default scale factor (can be read by other scripts)
var scale_factor: float = 1.0

func _ready():
    # keep this node alive as an autoload
    pass

func get_scale() -> float:
    return scale_factor

func set_scale(s: float) -> void:
    scale_factor = s
