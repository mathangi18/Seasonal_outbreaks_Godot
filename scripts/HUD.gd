extends CanvasLayer
class_name HUD
# FEATURES: see /FEATURES_GODOT_FULL.txt, section 7

@export var SHOW_SCOREBOARD: bool = true

var scoreboard_label: Label

func _ready():
	scoreboard_label = get_node_or_null("Control/Scoreboard")
	if scoreboard_label:
		scoreboard_label.visible = SHOW_SCOREBOARD

func update_scoreboard(data: Dictionary):
	if not SHOW_SCOREBOARD or not scoreboard_label:
		return
		
	var text = "Tick: %d\n" % data.get("tick", 0)
	text += "Susceptible: %d\n" % data.get("s", 0)
	text += "Exposed: %d\n" % data.get("e", 0)
	text += "Infectious: %d\n" % data.get("i", 0)
	text += "Recovered: %d\n" % data.get("r", 0)
	text += "Queued: %d\n" % data.get("queued", 0)
	text += "Hospitalized: %d\n" % data.get("hospitalized", 0)
	
	scoreboard_label.text = text

# UI Callbacks (to be connected in editor or via code if buttons existed)
func _on_start_pause_pressed():
	var sim = get_node_or_null("/root/Main/SimulationEngine")
	if sim and sim.timer:
		if sim.timer.paused:
			sim.timer.paused = false
		else:
			sim.timer.paused = true

func _on_reset_pressed():
	get_tree().reload_current_scene()

func _on_export_csv_pressed():
	# Trigger logger export if needed, but logger writes continuously
	pass

func _ready():
	scoreboard_label = get_node_or_null("Control/Scoreboard")
	if scoreboard_label:
		scoreboard_label.visible = SHOW_SCOREBOARD
		
	# Populate Scenario Select if exists
	var opt = get_node_or_null("Control/ScenarioSelect")
	if opt:
		opt.add_item("Load Scenario...")
		opt.add_item("Default")
		opt.add_item("High Density")
		opt.item_selected.connect(_on_scenario_selected)

func _on_scenario_selected(index):
	var opt = get_node_or_null("Control/ScenarioSelect")
	if index == 0: return
	
	var filename = ""
	if index == 1: filename = "default.json"
	if index == 2: filename = "high_density.json"
	
	if filename != "":
		load_scenario("res://scenarios/" + filename)

func load_scenario(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.data
			print("Loading scenario: ", data.get("name"))
			var sim = get_node_or_null("/root/Main/SimulationEngine")
			if sim:
				# Apply params
				sim.initial_population = data.get("initial_population", 100)
				sim.infection_radius = data.get("infection_radius", 20.0)
				sim.infection_prob = data.get("infection_prob", 0.1)
				# ... apply others ...
				# Reload scene to take effect (simple way)
				# In a real app we'd reset the engine state without reload
				get_tree().reload_current_scene()
