@tool
extends EditorPlugin
var _played := false
func _enter_tree():
    if not Engine.is_editor_hint(): return
    call_deferred('_try_play')
func _try_play():
    if _played: return
    _played = true
    var main = ProjectSettings.get_setting('application/run/main_scene')
    get_editor_interface().play_custom_scene(main)
