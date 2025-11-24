extends Node

func _ready():
	print("Validator: Starting scene-based validation...")
	await get_tree().process_frame
	
	# Check Core Scenes
	var scenes = ["res://scenes/Main.tscn", "res://scenes/Patient.tscn", "res://scenes/Facility.tscn", "res://scenes/HUD.tscn"]
	for s_path in scenes:
		var s = load(s_path)
		if s:
			print("Validator: Loaded ", s_path)
			var inst = s.instantiate()
			if inst:
				print("Validator: Instantiated ", s_path)
				inst.queue_free()
			else:
				print("Validator: ERROR - Failed to instantiate ", s_path)
				get_tree().quit(1)
		else:
			print("Validator: ERROR - Failed to load ", s_path)
			get_tree().quit(1)
			
	print("Validator: All checks passed.")
	get_tree().quit(0)
