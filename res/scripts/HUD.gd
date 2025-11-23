# res://scripts/HUD.gd
extends CanvasLayer

# Retry interval (seconds) to find the SimulationEngine if it is not yet available
const RETRY_INTERVAL := 0.5

var sim: Node = null
var _retry_timer := 0.0

func _ready():
	sim = _find_simulation_engine()
	if sim:
		_bind_to_simulation(sim)
	else:
		_retry_timer = 0.0
		print("HUD: SimulationEngine not found on ready(), will retry in process().")

func _process(delta):
	if sim == null:
		_retry_timer += delta
		if _retry_timer >= RETRY_INTERVAL:
			_retry_timer = 0.0
			sim = _find_simulation_engine()
			if sim:
				print("HUD: Found SimulationEngine in _process().")
				_bind_to_simulation(sim)
	else:
		if sim.has_method("get_counts"):
			var counts = sim.get_counts()
			_update_ui_from_counts(counts)
		else:
			# re-find in case we bound to a stub node
			var fallback = _find_simulation_engine()
			if fallback and fallback != sim:
				sim = fallback
				_bind_to_simulation(sim)

func _find_simulation_engine():
	var root = get_tree().get_root()
	# 1) Look by node name first
	var n = root.find_child("SimulationEngine", true, false)
	if n and n.has_method("get_counts"):
		return n
	# 2) Look in groups
	var group_nodes = get_tree().get_nodes_in_group("simulation")
	for gn in group_nodes:
		if gn and gn.has_method("get_counts"):
			return gn
	# 3) Full tree search for any node that implements get_counts()
	var stack = [root]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node != root and node.has_method("get_counts"):
			return node
		for i in range(node.get_child_count()):
			stack.push_back(node.get_child(i))
	return null

func _bind_to_simulation(s):
	if not s:
		return
	sim = s
	# Connect to counts_changed if provided
	if s.has_signal("counts_changed"):
		if not s.is_connected("counts_changed", Callable(self, "_on_counts_changed")):
			s.connect("counts_changed", Callable(self, "_on_counts_changed"))
	# Immediately populate UI
	if s.has_method("get_counts"):
		var counts = s.get_counts()
		_update_ui_from_counts(counts)
	else:
		print("HUD: bound node does not implement get_counts()")

func _on_counts_changed(counts):
	_update_ui_from_counts(counts)

func _update_ui_from_counts(counts):
	var text = "Stats\n"
	if typeof(counts) == TYPE_DICTIONARY:
		for k in counts.keys():
			text += str(k) + ": " + str(counts[k]) + "\n"
	elif typeof(counts) == TYPE_ARRAY:
		# fallback mapping if engine returns array [S,E,I,Sym,H,R]
		text += "S: %d\nE: %d\nI: %d\nSym: %d\nH: %d\nR: %d\n" % [counts[0],counts[1],counts[2],counts[3],counts[4],counts[5]]
	else:
		text += "(unknown counts format)\n"
	if has_node("Panel/Label"):
		get_node("Panel/Label").text = text
	elif has_node("StatsLabel"):
		get_node("StatsLabel").text = text
	else:
		# Safe fallback: create or update a Label under this node if missing
		if not has_node("StatsLabel"):
			var lbl = Label.new()
			lbl.name = "StatsLabel"
			add_child(lbl)
		get_node("StatsLabel").text = text
