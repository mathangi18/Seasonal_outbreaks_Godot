extends Node2D
class_name Patient
# FEATURES: see /FEATURES_GODOT_FULL.txt, section 5

enum State { SUSCEPTIBLE, EXPOSED, INFECTIOUS, RECOVERED }

var state: State = State.SUSCEPTIBLE

func _ready():
	pass

func infect():
	pass

func is_infectious() -> bool:
	return state == State.INFECTIOUS

func is_susceptible() -> bool:
	return state == State.SUSCEPTIBLE

func sim_tick(tick: int):
	pass
