extends Node
class_name SimulationEngine

@export var initial_population: int = 50
@export var facility_count: int = 2
@export var ambulance_count: int = 2
@export var infection_radius: float = 30.0
@export var infection_prob: float = 0.1

var patients: Array = []
var facilities: Array = []
var ambulances: Array = []
var current_tick: int = 0

var patient_scene = preload("res://scenes/Patient.tscn")
var facility_scene = preload("res://scenes/Facility.tscn")
var ambulance_scene = preload("res://scenes/Ambulance.tscn")

signal tick(current_tick)

func _ready():
	spawn_facilities()
	spawn_patients()
	spawn_ambulances()
	
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_on_tick)
	add_child(timer)
	timer.start()

func spawn_patients():
	for i in range(initial_population):
		var p = patient_scene.instantiate()
		get_parent().get_node("World").add_child(p)
		patients.append(p)
	# Infect one
	if patients.size() > 0:
		patients[0].infect()

func spawn_facilities():
	for i in range(facility_count):
		var f = facility_scene.instantiate()
		f.position = Vector2(randf_range(50, UIScale.world_width-50), randf_range(50, UIScale.world_height-50))
		get_parent().get_node("World").add_child(f)
		facilities.append(f)

func spawn_ambulances():
	for i in range(ambulance_count):
		var a = ambulance_scene.instantiate()
		a.position = Vector2(50, 50)
		get_parent().get_node("World").add_child(a)
		ambulances.append(a)

func _on_tick():
	current_tick += 1
	tick.emit(current_tick)
	
	# Update patients
	for p in patients:
		p.sim_tick(current_tick)
		
	# Infection spread
	for p in patients:
		if p.state == Patient.State.INFECTIOUS or p.state == Patient.State.SYMPTOMATIC:
			for other in patients:
				if other.state == Patient.State.SUSCEPTIBLE:
					if p.position.distance_to(other.position) < infection_radius:
						if randf() < infection_prob:
							other.infect()
							
	# Facilities
	for f in facilities:
		f.tick_service()
		
	# Ambulance Dispatch
	for p in patients:
		if p.state == Patient.State.SYMPTOMATIC and p.visible: # Visible means not already in ambulance/hospital
			# Find idle ambulance
			var amb = get_idle_ambulance()
			if amb:
				# Find nearest facility with capacity (or just any)
				var fac = facilities[0] # Simple logic
				amb.dispatch(p, fac)

func get_idle_ambulance():
	for a in ambulances:
		if a.state == Ambulance.State.IDLE:
			return a
	return null

func get_counts() -> Dictionary:
	var s=0; var e=0; var i=0; var sym=0; var r=0; var h=0
	for p in patients:
		match p.state:
			Patient.State.SUSCEPTIBLE: s+=1
			Patient.State.EXPOSED: e+=1
			Patient.State.INFECTIOUS: i+=1
			Patient.State.SYMPTOMATIC: sym+=1
			Patient.State.RECOVERED: r+=1
			Patient.State.HOSPITALIZED: h+=1
	return {"tick": current_tick, "s": s, "e": e, "i": i, "sym": sym, "r": r, "h": h}
