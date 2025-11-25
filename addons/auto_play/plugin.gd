@tool
extends EditorPlugin

# Auto-play plugin: when the plugin enters the tree (editor opens),
# play the main scene once and then do nothing further.
var _played := false

func _enter_tree() -> void:
    # Use call_deferred to ensure editor is fully initialized
    if not Engine.is_editor_hint(): 
        return
    call_deferred("_try_auto_play")

func _exit_tree() -> void:
    pass

func _try_auto_play() -> void:
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
        main_scene = "res://res/scenes/Main.tscn"
    print("AutoPlay plugin: Attempting to play scene: ", main_scene)
    # Play the main scene
    ei.play_custom_scene(main_scene)
