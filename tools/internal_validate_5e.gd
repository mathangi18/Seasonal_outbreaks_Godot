extends SceneTree

func _init():
    if ProjectSettings.has_setting("autoload/AudioManager"):
        print("INTERNAL_VALIDATION_5E_OK")
    else:
        print("INTERNAL_VALIDATION_5E_FAIL: AudioManager not in autoload")
    quit()
