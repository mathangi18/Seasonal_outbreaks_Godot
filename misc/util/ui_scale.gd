extends Node
class_name UIScale

# Constants from spec
const PATIENT_RADIUS = 3.0
const PATIENT_BASE_SPEED = 1.8
const WORLD_W = 600.0
const WORLD_H = 380.0

var scale_factor: float = 1.0
var world_width: float = WORLD_W
var world_height: float = WORLD_H

func _ready():
	var vp = get_viewport()
	if vp:
		var size = vp.get_visible_rect().size
		if size.x > 0 and size.y > 0:
			var sx = size.x / WORLD_W
			var sy = size.y / WORLD_H
			scale_factor = min(sx, sy)
			print("UIScale: Initialized with scale factor ", scale_factor)

func sx(x: float) -> float:
	return x * scale_factor

func sy(y: float) -> float:
	return y * scale_factor

func ss(size: float) -> float:
	return size * scale_factor
