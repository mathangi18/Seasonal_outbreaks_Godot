tool
extends EditorPlugin

# Auto-play plugin: when the plugin enters the tree (editor opens),
# play the main scene once and then do nothing further.
var _played := false

func _enter_tree() -> void:
    # connect to the editor's idle frame so the editor is fully initialized
    if not Engine.is_editor_hint(): 
        return
    get_tree().connect("idle_frame", Callable(self, "_on_idle_frame"))

func _exit_tree() -> void:
    if get_tree().is_connected("idle_frame", Callable(self, "_on_idle_frame")):
        get_tree().disconnect("idle_frame", Callable(self, "_on_idle_frame"))

func _on_idle_frame() -> void:
    if _played:
        return
    _played = true
    # Get editor interface
    var ei := get_editor_interface()
    if ei == null:
        print("AutoPlay plugin: editor_interface not found")
        return
    # Determine main scene from ProjectSettings, fallback to res://scenes/Main.tscn
    var main_scene := ProjectSettings.get_setting("application/run/main_scene", "")
    if main_scene == "":
        main_scene = "res://scenes/Main.tscn"
    # Ask editor to play the main scene
    # play_main_scene is the intended EditorInterface method; if not present, try play_current_scene
    if ei.has_method("play_main_scene"):
        ei.play_main_scene()
    elif ei.has_method("play_current_scene"):
        ei.play_current_scene()
    else:
        # fallback: request to open the main scene in editor (non-play)
        print("AutoPlay plugin: neither play_main_scene nor play_current_scene available; opening main scene instead.")
        ei.open_scene_from_path(main_scene)
