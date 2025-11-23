extends Node2D

@onready var camera = $Camera2D
@onready var label = $CanvasLayer/Label

var cutscene_time: float = 0.0
var cutscene_duration: float = 8.0

func _ready():
    # Start cinematic
    if camera:
        camera.position = Vector2(0, 0)
        camera.zoom = Vector2(0.5, 0.5)
    
    if label:
        label.text = "SEASONAL OUTBREAK SIMULATION"
        label.modulate = Color(1, 1, 1, 0)
    
    if AudioManager:
        AudioManager.play_sfx("cinematic_sting")

func _process(delta):
    cutscene_time += delta
    var t = cutscene_time / cutscene_duration
    
    # Fade in title
    if label and t < 0.3:
        label.modulate = Color(1, 1, 1, t / 0.3)
    elif label and t > 0.7:
        label.modulate = Color(1, 1, 1, 1.0 - (t - 0.7) / 0.3)
    
    # Camera dolly
    if camera:
        camera.position = Vector2(t * 1152, t * 648)
        camera.zoom = Vector2(0.5 + t * 0.5, 0.5 + t * 0.5)
    
    # End cutscene
    if t >= 1.0:
        get_tree().change_scene_to_file("res://scenes/Main.tscn")
