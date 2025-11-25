extends Node2D

# TEST MODE = tiny numbers (keeps things light for testing)
const TEST_MODE := true

const PATIENT_COUNT_TEST := 5
const FACILITY_COUNT_TEST := 1
const AMBULANCE_COUNT_TEST := 1

const PATIENT_COUNT_PROD := 50
const FACILITY_COUNT_PROD := 3
const AMBULANCE_COUNT_PROD := 3

var patient_scene = preload("res://scenes/Patient.tscn")
var facility_scene = preload("res://scenes/Facility.tscn")
var ambulance_scene = preload("res://scenes/Ambulance.tscn")

func _ready():
	# create a Camera2D at runtime so viewport is controlled by code
	var cam := Camera2D.new()
	cam.enabled = true
	# zoom < 1 = zoomed out (show more). Tweak if you want more/less.
	cam.zoom = Vector2(0.6, 0.6)
	# position roughly at center of expected spawn region
	cam.position = Vector2(500, 350)
	add_child(cam)

	print("MAIN: Spawning entities...")
	randomize()

	var patient_count : int
	var facility_count : int
	var ambulance_count : int

	if TEST_MODE:
		patient_count = PATIENT_COUNT_TEST
		facility_count = FACILITY_COUNT_TEST
		ambulance_count = AMBULANCE_COUNT_TEST
	else:
		patient_count = PATIENT_COUNT_PROD
		facility_count = FACILITY_COUNT_PROD
		ambulance_count = AMBULANCE_COUNT_PROD

	# spawn patients and ensure they get the runtime movement script
	for i in range(patient_count):
		var p = patient_scene.instantiate()
		# set a position inside camera view
		p.position = Vector2(randf() * 800 + 100, randf() * 400 + 100)
		# attach the movement script at runtime so you don't need to edit the scene
		p.set_script(load("res://scripts/Patient.gd"))
		add_child(p)

	for i in range(facility_count):
		var f = facility_scene.instantiate()
		f.position = Vector2(100 + i * 300, 200)
		add_child(f)

	for i in range(ambulance_count):
		var a = ambulance_scene.instantiate()
		a.position = Vector2(100 + i * 300, 500)
		add_child(a)

	print("MAIN: Spawn complete. (patients=%d, facilities=%d, ambulances=%d)" %
		[patient_count, facility_count, ambulance_count])
