extends SceneTree

func _init():
	print("Starting headless simulation run...")
	
	# 1. Load Main Scene
	var main_scene = load("res://scenes/Main.tscn")
	if not main_scene:
		print("ERROR: Could not load Main.tscn")
		quit(1)
		return
		
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	
	# 2. Find SimulationEngine
	var sim = main_node.get_node_or_null("SimulationEngine")
	if not sim:
		print("ERROR: SimulationEngine not found in Main scene.")
		quit(1)
		return
		
	# 3. Run Simulation
	# Parse args for ticks
	var ticks = 200
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--ticks="):
			ticks = int(arg.split("=")[1])
			
	print("Running for %d ticks..." % ticks)
	
	# Force ready if not already called (add_child calls it, but just to be safe/explicit)
	# sim._ready() 
	
	for i in range(ticks):
		sim._tick()
		if i % 50 == 0:
			print("Tick: %d" % i)
			
	print("Simulation run complete.")
	
	# 4. Verify Log
	var log_path = "user://logs/sim_log.csv"
	if FileAccess.file_exists(log_path):
		print("Log file created at: %s" % log_path)
		var f = FileAccess.open(log_path, FileAccess.READ)
		print("Log Header: %s" % f.get_line())
		print("Log Last Line: %s" % f.get_line()) # Just read next line
	else:
		print("ERROR: Log file not found.")
		quit(1)
		return
		
	quit(0)
