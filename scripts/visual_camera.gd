extends Camera2D

# MANDATORY PARAMETERS
var smoothing_speed_val: float = 5.0
var default_zoom: Vector2 = Vector2(0.85, 0.85)
var default_offset: Vector2 = Vector2(0, -40)

# State
var target_node: Node2D = null
var shake_timer: float = 0.0
var shake_amount: float = 0.0
var pulse_timer: float = 0.0
var pulse_duration: float = 0.0

func _ready():
	# Enforce mandatory parameters
	position_smoothing_enabled = true
	position_smoothing_speed = smoothing_speed_val
	zoom = default_zoom
	offset = default_offset
	
	# Ensure we are the current camera
	make_current()

func _process(delta: float):
	if target_node and is_instance_valid(target_node):
		position = target_node.position
		
	if shake_timer > 0:
		shake_timer -= delta
		offset = default_offset + Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
	else:
		offset = default_offset
		
	if pulse_timer > 0:
		pulse_timer -= delta
		var t = 1.0 - (pulse_timer / pulse_duration)
		# Simple sine pulse for zoom effect
		var pulse_scale = 1.0 + (sin(t * PI) * 0.05)
		zoom = default_zoom * pulse_scale
	else:
		zoom = default_zoom

# REQUIRED METHODS
func set_target(node_path_or_node):
	if node_path_or_node is Node:
		target_node = node_path_or_node
	elif node_path_or_node is NodePath:
		var node = get_node_or_null(node_path_or_node)
		if node:
			target_node = node
	elif node_path_or_node is String:
		var node = get_node_or_null(node_path_or_node)
		if node:
			target_node = node

func pulse_zoom(duration_sec: float):
	pulse_duration = duration_sec
	pulse_timer = duration_sec

func shake(duration_sec: float, amount: float = 5.0):
	shake_timer = duration_sec
	shake_amount = amount

