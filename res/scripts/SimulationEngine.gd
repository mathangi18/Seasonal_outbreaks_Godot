# res://scripts/SimulationEngine.gd
extends Node

# Minimal SimulationEngine stub to start the simulation build.
# Responsibilities to add later: spawn patients, manage queues, handle facilities, log KPIs.
var started := false

func _ready():
    # placeholder log so we see the engine loaded
    print("SimulationEngine: ready")
    started = true

func step(delta):
    # called by other systems for simulation ticks (to be wired later)
    pass
