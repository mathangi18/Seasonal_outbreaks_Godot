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
var timer: Timer
var patients: Array = []
var facilities: Array = []
var scale_utils

# References to scenes
var patient_scene = preload("res://scenes/Patient.tscn")
var facility_scene = preload("res://scenes/Facility.tscn")

func _ready():
	seed(RNG_seed)
	scale_utils = get_node("/root/Main/ScaleUtils") # Assuming ScaleUtils is autoloaded or child of Main
	if not scale_utils:
		# Fallback if not found in tree, try to find by type or load dynamically
		# For this scaffold, we'll assume it's a sibling or we load it
		scale_utils = load("res://scripts/scale_utils.gd").new()
		add_child(scale_utils)
		scale_utils._ready()

	setup_timer()
	spawn_facilities()
	spawn_patients(initial_population)
	
	# Initial log
	log_status()

func setup_timer():
	timer = Timer.new()
	timer.wait_time = tick_interval
	timer.one_shot = false
	timer.timeout.connect(_tick)
	add_child(timer)
	timer.start()

func spawn_patients(count: int):
	for i in range(count):
		var p = patient_scene.instantiate()
		# Random position via scale_utils
		var pos = scale_utils.get_random_pos()
		p.position = pos
		# Add to scene tree
		get_parent().get_node("World").add_child(p)
		patients.append(p)
		
	# Infect one patient initially
	if patients.size() > 0:
		patients[0].infect()
		emit_signal("patient_infected", patients[0])

func spawn_facilities():
	# Spawn at least one facility
	var f = facility_scene.instantiate()
	f.position = scale_utils.get_random_pos()
	f.capacity = facility_capacity
	f.service_rate = facility_service_rate
	get_parent().get_node("World").add_child(f)
	facilities.append(f)

func _tick():
	current_tick += 1
	emit_signal("tick", current_tick)
	
	# Update patients
	for p in patients:
		if p.has_method("sim_tick"):
			p.sim_tick(current_tick)
			
	# Infection check (Naive O(N^2) for now)
	check_infections()
	
	# Facility service
	for f in facilities:
		if f.has_method("tick_service"):
			f.tick_service()
			
	# Update Scoreboard (via signal or direct call to HUD)
	update_hud()
	
	# Log
	log_status()

func check_infections():
	# Spatial Grid Optimization
	var grid = load("res://scripts/spatial_grid.gd").new(scale_utils.world_width, scale_utils.world_height, infection_radius * 2.0)
	
	# Populate grid
	for p in patients:
		if p.is_susceptible() or p.is_infectious():
			grid.add(p)
			
	# Check infections
	for p in patients:
		if p.is_infectious():
			var nearby = grid.get_nearby(p)
			for potential_victim in nearby:
				if potential_victim.is_susceptible():
					var dist = p.position.distance_to(potential_victim.position)
					if dist < scale_utils.ss(infection_radius):
						if randf() < infection_prob:
							potential_victim.infect()
							emit_signal("patient_infected", potential_victim)

func update_hud():
	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("update_scoreboard"):
		var counts = get_counts()
		hud.update_scoreboard(counts)

func log_status():
	var logger = get_node_or_null("/root/Main/Logger")
	if logger and logger.has_method("log_counts"):
		var c = get_counts()
		logger.log_counts(current_tick, c.s, c.e, c.i, c.r, c.queued, c.hospitalized)

func get_counts() -> Dictionary:
	var s = 0
	var e = 0
	var i = 0
	var r = 0
	for p in patients:
		match p.state:
			0: s += 1 # SUSCEPTIBLE
			1: e += 1 # EXPOSED
			2: i += 1 # INFECTIOUS
			3: r += 1 # RECOVERED
	
	var queued = 0
	var hospitalized = 0
	for f in facilities:
		queued += f.queue.size()
		hospitalized += f.occupants.size()
		
	return {"tick": current_tick, "s": s, "e": e, "i": i, "r": r, "queued": queued, "hospitalized": hospitalized}
