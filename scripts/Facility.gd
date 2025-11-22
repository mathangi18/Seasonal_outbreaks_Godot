extends Node2D
class_name Facility
# FEATURES: see /FEATURES_GODOT_FULL.txt, section 6

@export var capacity: int = 10
@export var service_rate: int = 1

var occupants: Array = []
var queue: Array = []

func _ready():
	pass

func admit(patient) -> bool:
	return false

func enqueue(patient):
	pass

func tick_service():
	pass
