extends Node2D
class_name Patient

@export var health := 100
@export var patient_id := -1

signal died(id)

func damage(amount:int):
    health = max(health - amount, 0)
    if health == 0:
        emit_signal("died", patient_id)