# HUD
# Displays simulation statistics and controls.
# Updates the UI labels based on data from the SimulationEngine.
# If you need to render more assets, see migration/render_requests.json.
﻿extends CanvasLayer

@onready var sim_engine = get_node("/root/Main/SimulationEngine")
@onready var label = $Panel/Label

var visible_anim: bool = true
var fade_time: float = 0.0

func _ready():
    # Setup animated panel
    if has_node("Panel"):
        $Panel.modulate = Color(1, 1, 1, 0)
        fade_in()

func _process(delta):
    if sim_engine and sim_engine.has_method("get_counts"):
        var counts = sim_engine.get_counts()
        label.text = "Tick: %d | S:%d E:%d I:%d Sym:%d R:%d H:%d" % [
            counts.get("Tick", 0),
            counts.get("S", 0),
            counts.get("E", 0),
            counts.get("I", 0),
            counts.get("Sym", 0),
            counts.get("R", 0),
            counts.get("H", 0)
        ]
    
    # Animate fade
    if fade_time > 0:
        fade_time -= delta
        if has_node("Panel"):
            var alpha = 1.0 - (fade_time / 1.0)
            $Panel.modulate = Color(1, 1, 1, clamp(alpha, 0, 1))

func fade_in():
    fade_time = 1.0
    if AudioManager:
        AudioManager.play_sfx("ui_pop")

func fade_out():
    if has_node("Panel"):
        var tween = create_tween()
        tween.tween_property($Panel, "modulate:a", 0.0, 0.5)
