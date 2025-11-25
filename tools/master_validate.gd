extends SceneTree

func _init():
    print("MASTER_VALIDATION_START")
    
    # 1. HEALTH CHECK (Load Main)
    var main_pack = load("res://scenes/Main.tscn")
    if main_pack:
        print("HEALTH_CHECK_OK")
    else:
        print("HEALTH_CHECK_FAIL")
        quit()
        return

    # 2. SMOKE TEST (Instantiate & Tick)
    var instance = main_pack.instantiate()
    if instance:
        root.add_child(instance)
        await process_frame
        await process_frame
        print("SMOKE_OK")
    else:
        print("SMOKE_FAIL")
        quit()
        return

    # 3. AUDIO CHECK
    # Check for AudioManager autoload
    if ProjectSettings.has_setting("autoload/AudioManager"):
        print("AG_AUDIO_OK")
    else:
        print("AG_AUDIO_FAIL: AudioManager missing")

    quit()
