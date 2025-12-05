extends Camera2D
class_name CameraController

@export var follow_target: Node2D
@export var follow_strength := 0.12
@export var orbit_strength := 0.06

var manual_offset := Vector2.ZERO
var orbit_angle := 0.0

func _process(delta):
    if follow_target:
        global_position = global_position.lerp(follow_target.global_position + manual_offset, follow_strength)
    if Input.is_action_pressed("orbit_left"):
        orbit_angle -= delta * 2.0
    if Input.is_action_pressed("orbit_right"):
        orbit_angle += delta * 2.0
    var offset := Vector2(150,0).rotated(orbit_angle)
    global_position = global_position.lerp(global_position + offset, orbit_strength)