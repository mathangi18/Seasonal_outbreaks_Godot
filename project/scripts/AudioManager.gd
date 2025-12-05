extends Node
class_name AudioManager

var ui_player: AudioStreamPlayer

func _ready():
    ui_player = AudioStreamPlayer.new()
    add_child(ui_player)

func play_ui(stream: AudioStream) -> void:
    if stream == null:
        return

    ui_player.stop()
    ui_player.stream = stream
    ui_player.play()

    var duration := 0.0
    if stream and stream.has_method("get_length"):
        duration = float(stream.get_length())

    if duration > 0.0:
        call_deferred("_schedule_stop", duration + 0.1)

func _schedule_stop(delay: float) -> void:
    var timer := get_tree().create_timer(delay)
    await timer.timeout
    if ui_player:
        ui_player.stop()
        ui_player.stream = null