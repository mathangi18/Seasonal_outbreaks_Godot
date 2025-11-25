extends SceneTree

func _init():
    print("INTERNAL_VALIDATION_START")
    var main = load("res://scenes/Main.tscn")
    if main:
        var instance = main.instantiate()
        if instance:
            print("INTERNAL_VALIDATION_OK")
        else:
            print("INTERNAL_VALIDATION_FAIL: Could not instantiate Main.tscn")
    else:
        print("INTERNAL_VALIDATION_FAIL: Could not load Main.tscn")
    quit()
