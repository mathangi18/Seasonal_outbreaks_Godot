extends Node

var sample_duration := 6.0
var sample_interval := 0.5
var elapsed := 0.0
var last_total := 0
var next_tick := 0.0

func _ready():
	print("\n=== NODE WATCH VERBOSE START ===")
	print("Initial total nodes:", get_tree().get_node_count())
	next_tick = sample_interval

func _process(delta):
	elapsed += delta
	if elapsed >= sample_duration:
		print("=== NODE WATCH VERBOSE END ===\n")
		queue_free()
		return
	
	if elapsed >= next_tick:
		_do_sample()
		next_tick += sample_interval

func _do_sample():
	var total = get_tree().get_node_count()
	var diff = total - last_total
	print("--- SAMPLE  total =", total, " (delta=", diff, ") ---")
	
	var counts := {}
	_collect_counts(get_tree().get_root(), counts)

	# Godot 4 sorting: use sort_custom with Callable
	var keys = counts.keys()
	keys.sort_custom(Callable(self, "_compare_counts").bind(counts))

	for i in range(min(6, keys.size())):
		var key = keys[i]
		print(str(i+1) + ": " + key + " => " + str(counts[key]))
	
	last_total = total

func _collect_counts(n: Node, counts: Dictionary) -> void:
	var key = n.get_class() + " <" + n.name + ">"
	counts[key] = counts.get(key, 0) + 1
	for c in n.get_children():
		_collect_counts(c, counts)

func _compare_counts(a, b, counts):
	# descending
	return counts[b] - counts[a]
