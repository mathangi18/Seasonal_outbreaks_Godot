extends Node
# FEATURES: see /FEATURES_GODOT_FULL.txt, section 3

# Fail-safe constants
const FAILSAFE_PATIENT_RADIUS = 3.0
const FAILSAFE_PATIENT_BASE_SPEED = 1.8
const FAILSAFE_WORLD_W = 600.0
const FAILSAFE_WORLD_H = 380.0

var world_width: float = FAILSAFE_WORLD_W
var world_height: float = FAILSAFE_WORLD_H
var scale_factor: float = 1.0

func _ready():
	# Auto-init if not called manually, using viewport size
	var viewport = get_viewport()
	if viewport:
		init(viewport, FAILSAFE_WORLD_W, FAILSAFE_WORLD_H)
	else:
		print("ScaleUtils: Viewport not found, using fail-safe defaults.")

func init(viewport: Viewport, target_w: float, target_h: float):
	if not viewport:
		print("ScaleUtils: Invalid viewport passed to init.")
		return
		
	var size = viewport.get_visible_rect().size
	if size.x == 0 or size.y == 0:
		print("ScaleUtils: Viewport size is 0, using fail-safe.")
		return

	# Calculate scale to fit target world into viewport
	var scale_x = size.x / target_w
	var scale_y = size.y / target_h
	scale_factor = min(scale_x, scale_y)
	
	world_width = target_w
	world_height = target_h
	
	print("ScaleUtils initialized: Scale=", scale_factor, " World=", world_width, "x", world_height)

func sx(x: float) -> float:
	return x * scale_factor

func sy(y: float) -> float:
	return y * scale_factor

func ss(size: float) -> float:
	return size * scale_factor

func get_random_pos() -> Vector2:
	return Vector2(randf_range(0, world_width), randf_range(0, world_height))
