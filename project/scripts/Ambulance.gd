extends Node2D
class_name Ambulance

@export var speed := 220.0

func move_to(target: Vector2, delta: float):
    global_position += (target - global_position).normalized() * speed * delta