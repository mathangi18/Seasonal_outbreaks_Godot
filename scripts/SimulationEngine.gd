extends Node
class_name SimulationEngine

var tick := 0
var patients: Array = []

func run_steps(steps: int, rng: RandomNumberGenerator) -> Dictionary:
    for i in range(steps):
        _step(rng)
    return { "ticks": tick, "patients": patients.size() }

func _step(rng: RandomNumberGenerator):
    if rng.randi_range(0,99) < 5:
        patients.append({ "id": tick, "health": rng.randi_range(50,100) })
    for p in patients:
        p.health = max(p.health - 1, 0)
    tick += 1