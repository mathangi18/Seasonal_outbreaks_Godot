extends Node
class_name SimulationEngine

signal counts_changed
var tick = 0

func _ready():
    print('SimulationEngine: ready')
    set_process(true)

func start_simulation():
    tick = 0
    print('SimulationEngine: start_simulation')

func get_counts() -> Dictionary:
    return {'S':0, 'E':0, 'I':0, 'Sym':0, 'R':0, 'H':0}
