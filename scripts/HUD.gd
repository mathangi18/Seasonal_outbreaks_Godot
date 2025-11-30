# HUD
# Displays simulation statistics and controls.
# Updates the UI labels based on data from the SimulationEngine.
# If you need to render more assets, see migration/render_requests.json.
extends CanvasLayer

@onready var label = $Control/Label
@onready var sim = get_node("../SimulationEngine")

# Audio
var ui_player: AudioStreamPlayer

func _ready():
    # Setup UI audio
    ui_player = AudioStreamPlayer.new()
    add_child(ui_player)
    if ResourceLoader.exists("res://res/assets/sounds/ui_pop.ogg"):
        ui_player.stream = ResourceLoader.load("res://res/assets/sounds/ui_pop.ogg")

func play_ui_sound():
    if ui_player and ui_player.stream:
        ui_player.play()

func _process(delta):
    if sim:
        var c = sim.get_counts()
        # Keys: S, E, I, Sym, R, H, Tick
        label.text = "Tick: %d\nS: %d\nE: %d\nI: %d\nSym: %d\nR: %d\nH: %d" % [c.Tick, c.S, c.E, c.I, c.Sym, c.R, c.H]
