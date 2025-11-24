extends SceneTree

func _init():
	print("ValidatorMainLoop: Starting...")
	
	# Check Resources
	var res_to_check = [
		"res://scenes/Main.tscn",
		"res://res/scripts/SimulationEngine.gd",
		"res://misc/util/ui_scale.gd"
	]
	
	for path in res_to_check:
		if ResourceLoader.exists(path):
			print("ValidatorMainLoop: Found ", path)
		else:
			print("ValidatorMainLoop: ERROR - Missing ", path)
			quit(1)
			return
			
	print("ValidatorMainLoop: Checks passed.")
	quit(0)
