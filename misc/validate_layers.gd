extends Node

func _ready():
	print("LayerValidator: Checking layers...")
	
	# Check Collision Layers
	var p = load("res://scenes/Patient.tscn").instantiate()
	if p.collision_layer != 2: # Layer 2
		print("ERROR: Patient collision layer incorrect. Expected 2, got ", p.collision_layer)
		get_tree().quit(1)
		return
		
	var f = load("res://scenes/Facility.tscn").instantiate()
	if f.collision_layer != 4: # Layer 3 (value 4)
		print("ERROR: Facility collision layer incorrect. Expected 4, got ", f.collision_layer)
		get_tree().quit(1)
		return
		
	var a = load("res://scenes/Ambulance.tscn").instantiate()
	if a.collision_layer != 8: # Layer 4 (value 8)
		print("ERROR: Ambulance collision layer incorrect. Expected 8, got ", a.collision_layer)
		get_tree().quit(1)
		return
		
	print("LayerValidator: All layer checks passed.")
	get_tree().quit(0)
