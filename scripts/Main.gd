extends Node
class_name Main

# Preload SimulationEngine to ensure parser sees the type.
var SimulationEngineSC = preload("res://scripts/SimulationEngine.gd")
var engine : Node = null

func _ready():
    engine = SimulationEngineSC.new()
    add_child(engine)

func run_sim(steps: int = 1000) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    # engine provides run_steps
    if engine and engine.has_method("run_steps"):
        return engine.run_steps(steps, rng)
    return {"ticks":0, "patients":0}