extends CanvasLayer

@onready var label = $Control/Label
@onready var sim = get_node("../SimulationEngine")

func _process(delta):
	if sim:
		var c = sim.get_counts()
		label.text = "Tick: %d\nS: %d\nE: %d\nI: %d\nSym: %d\nR: %d\nH: %d" % [c.tick, c.s, c.e, c.i, c.sym, c.r, c.h]
