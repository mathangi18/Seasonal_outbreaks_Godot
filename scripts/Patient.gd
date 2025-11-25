extends Node2D

# Simple movement script for Patient instances.
# Moves to the right at `speed`. Wraps around when it goes too far to keep visible.
var speed := 70.0

func _physics_process(delta):
    position.x += speed * delta
    # simple wrap so they remain in view during test
    if position.x > 1100:
        position.x = -100
