extends SceneTree

func _init():
	print("Starting validation...")
	
	# 1. Check resources
	var main = load("res://scenes/Main.tscn")
	if not main:
		print("ERROR: Main.tscn not found or failed to load.")
		quit(1)
		return
		
	# 2. Instance Main
	var main_node = main.instantiate()
	if not main_node:
		print("ERROR: Failed to instance Main scene.")
		quit(1)
		return
		
	# 3. Check SimulationEngine
	var sim = main_node.get_node("SimulationEngine")
	if not sim:
		print("ERROR: SimulationEngine node missing in Main.")
		quit(1)
		return
		
	# 4. Run short sim
	print("Running 200 ticks...")
	sim._ready()
	for i in range(200):
		sim._tick()
		
	# 5. Check logs
	var file = FileAccess.open("user://logs/sim_log.csv", FileAccess.READ)
	if not file:
		print("ERROR: Log file not created.")
		quit(1)
		return
		
	print("Validation PASSED.")
	quit(0)
