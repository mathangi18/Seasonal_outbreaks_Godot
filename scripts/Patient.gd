extends Node2D
class_name Patient
# FEATURES: see /FEATURES_GODOT_FULL.txt, section 5

enum State { SUSCEPTIBLE, EXPOSED, INFECTIOUS, RECOVERED }

var state: State = State.SUSCEPTIBLE
var target_pos: Vector2
var speed: float = 10.0
var scale_utils

# Timers for state transitions
var exposed_ticks: int = 0
var infectious_ticks: int = 0

# Config from SimulationEngine (set on spawn)
var incubation_period: int = 5
var recovery_period: int = 10

func _ready():
	scale_utils = get_node_or_null("/root/Main/ScaleUtils")
	if not scale_utils:
		# Fallback
		scale_utils = load("res://scripts/scale_utils.gd").new()
		scale_utils._ready()
		
	# Initial random target
	pick_new_target()
	update_visuals()

func infect():
	if state == State.SUSCEPTIBLE:
		state = State.EXPOSED
		exposed_ticks = 0
		update_visuals()

func is_infectious() -> bool:
	return state == State.INFECTIOUS

func is_susceptible() -> bool:
	return state == State.SUSCEPTIBLE

func sim_tick(tick: int):
	# Movement
	move_towards_target()
	
	# State transitions
	match state:
		State.EXPOSED:
			exposed_ticks += 1
			if exposed_ticks >= incubation_period:
				state = State.INFECTIOUS
				infectious_ticks = 0
				update_visuals()
		State.INFECTIOUS:
			infectious_ticks += 1
			if infectious_ticks >= recovery_period:
				state = State.RECOVERED
				update_visuals()

func move_towards_target():
	var dist = position.distance_to(target_pos)
	if dist < 5.0:
		pick_new_target()
	else:
		var dir = (target_pos - position).normalized()
		position += dir * scale_utils.ss(speed) * 0.5 # 0.5 is tick interval approx, should use delta but this is tick based

func pick_new_target():
	if scale_utils:
		target_pos = scale_utils.get_random_pos()
	else:
		target_pos = Vector2(randf_range(0, 600), randf_range(0, 380))

func update_visuals():
	var sprite = get_node_or_null("Sprite2D")
	var halo = get_node_or_null("Halo")
	
	var color = Color.GREEN
	match state:
		State.SUSCEPTIBLE: color = Color.GREEN
		State.EXPOSED: color = Color.YELLOW
		State.INFECTIOUS: color = Color.RED
		State.RECOVERED: color = Color.BLUE
	
	if sprite:
		sprite.modulate = color
	if halo:
		halo.color = color
		halo.energy = 1.0 if state == State.INFECTIOUS else 0.5
