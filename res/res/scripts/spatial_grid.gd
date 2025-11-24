extends Node
class_name SpatialGrid
# FEATURES: see /FEATURES_GODOT_FULL.txt, section 9 (Optimization)

var cell_size: float = 50.0
var grid: Dictionary = {}
var width: float = 600.0
var height: float = 380.0

func _init(w: float, h: float, c_size: float):
	width = w
	height = h
	cell_size = c_size

func clear():
	grid.clear()

func add(patient):
	var cell = get_cell(patient.position)
	if not grid.has(cell):
		grid[cell] = []
	grid[cell].append(patient)

func get_nearby(patient) -> Array:
	var nearby = []
	var cell = get_cell(patient.position)
	
	# Check 3x3 neighbors
	for x in range(cell.x - 1, cell.x + 2):
		for y in range(cell.y - 1, cell.y + 2):
			var key = Vector2i(x, y)
			if grid.has(key):
				nearby.append_array(grid[key])
				
	return nearby

func get_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / cell_size), int(pos.y / cell_size))
