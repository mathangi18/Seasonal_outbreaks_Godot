extends Node
class_name SpawnGenerator

@export var spawn_rate := 0.03
var rng := RandomNumberGenerator.new()

func _ready():
    rng.randomize()

func maybe() -> Variant:
    if rng.randf() < spawn_rate:
        return {"id": rng.randi(), "type": "patient"}
    return null