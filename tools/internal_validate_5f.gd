extends SceneTree

func _init():
    print("SMOKE_TEST_START")
    var main = load("res://scenes/Main.tscn")
    if main:
        var instance = main.instantiate()
        root.add_child(instance)
        
        # Simulate a frame
        await process_frame
        
        print("INTERNAL_VALIDATION_5F_OK")
    else:
        print("INTERNAL_VALIDATION_5F_FAIL: Could not load Main")
    quit()
