extends Node

# Preload scenes
var patient_scene = preload("res://res/scenes/Patient.tscn")
var facility_scene = preload("res://res/scenes/Facility.tscn")
var ambulance_scene = preload("res://res/scenes/Ambulance.tscn")

# References
var simulation_engine: SimulationEngine
var camera: CameraController
var hud: HUD

func _ready():
	print("Main: Initializing simulation...")
	
	# Create and add SimulationEngine
	simulation_engine = SimulationEngine.new()
	simulation_engine.name = "SimulationEngine"
	simulation_engine.add_to_group("simulation")
	add_child(simulation_engine)
	print("Main: SimulationEngine created and added to group 'simulation'")
	
	# Create and add CameraController
	camera = CameraController.new()
	camera.name = "Camera"
	camera.position = Vector2(512, 384)  # Center of a 1024x768 viewport
	add_child(camera)
	print("Main: CameraController created")
	
	# Create and add HUD
	hud = HUD.new()
	hud.name = "HUD"
	hud.engine = simulation_engine
	add_child(hud)
	print("Main: HUD created and connected to SimulationEngine")
	
	# Create 3 Facilities (spread out)
	var facility_positions = [
		Vector2(200, 200),
		Vector2(824, 200),
		Vector2(512, 568)
	]
	
	for i in range(3):
		var facility = facility_scene.instantiate()
		facility.name = "Facility" + str(i)
		facility.position = facility_positions[i]
		add_child(facility)
	print("Main: Created 3 Facilities")
	
	# Create 100 Patients (random positions)
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(100):
		var patient = patient_scene.instantiate()
		patient.name = "Patient" + str(i)
		patient.position = Vector2(
			rng.randf_range(50, 974),
			rng.randf_range(50, 718)
		)
		add_child(patient)
	print("Main: Created 100 Patients")
	
	# Create 3 Ambulances (random positions)
	for i in range(3):
		var ambulance = ambulance_scene.instantiate()
		ambulance.name = "Ambulance" + str(i)
		ambulance.position = Vector2(
			rng.randf_range(100, 924),
			rng.randf_range(100, 668)
		)
		add_child(ambulance)
	print("Main: Created 3 Ambulances")
	
	# Start the simulation
	simulation_engine.start_simulation()
	print("Main: Simulation started!")
