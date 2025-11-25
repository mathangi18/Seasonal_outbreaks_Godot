extends SceneTree

func _init():
    var main = load("res://scenes/Main.tscn")
    if main:
        var instance = main.instantiate()
        if instance.get_script() != null:
            print("INTERNAL_VALIDATION_5D_OK")
        else:
            print("INTERNAL_VALIDATION_5D_FAIL: No script attached to Main")
    else:
        print("INTERNAL_VALIDATION_5D_FAIL: Could not load Main")
    quit()
