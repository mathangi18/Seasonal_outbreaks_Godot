tool
extends EditorPlugin
func _enter_tree():
    if not Engine.is_editor_hint(): return
    # Wait a frame then run
    get_tree().create_timer(1.0).timeout.connect(func(): get_editor_interface().play_custom_scene("res://res/res/scenes/Main.tscn"))
