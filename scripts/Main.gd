extends Node

@onready var sim = $SimulationEngine

func _ready():
    if sim:
        sim.start_simulation()
