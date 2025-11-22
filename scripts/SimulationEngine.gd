extends Node
class_name SimulationEngine
# FEATURES: see /FEATURES_GODOT_FULL.txt, section 4

signal tick(current_tick)
signal patient_infected(patient_node)
signal patient_recovered(patient_node)
signal facility_overloaded(facility_node)

@export var tick_interval: float = 0.5
@export var initial_population: int = 100
@export var infection_radius: float = 20.0
@export var infection_prob: float = 0.1
@export var incubation_ticks: int = 5
@export var infectious_ticks: int = 10
@export var patient_speed: float = 10.0
@export var facility_capacity: int = 10
@export var facility_service_rate: int = 1
@export var RNG_seed: int = 12345

var current_tick: int = 0

func _ready():
	pass

func spawn_patients(count: int):
	pass

func spawn_facilities():
	pass

func _tick():
	pass
