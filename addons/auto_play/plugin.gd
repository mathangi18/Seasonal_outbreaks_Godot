@tool
extends EditorPlugin
func _enter_tree():
    if not Engine.is_editor_hint(): return
    # Wait a bit for editor to settle
    get_tree().create_timer(2.0).timeout.connect(func():
        print("AutoPlay: Triggering Main Scene...")
        get_editor_interface().play_custom_scene("res://scenes/Main.tscn")
    )
