# res://tools/run_main_visual.gd - temporary helper script for AG
extends MainLoop
func _init():
    var f = load("res://res/scenes/Main.tscn")
    if f:
        var inst = f.instantiate()
        get_tree().root.add_child(inst)
        # give time for node setup
        call_deferred("_play")
    else:
        print("ERROR: Could not load res://res/scenes/Main.tscn")

func _play():
    # optionally call a known start method
    var main = get_tree().root.get_node("Main") if get_tree().root.has_node("Main") else null
    if main and main.has_method("start_simulation"):
        main.start_simulation()
    # keep editor open; quit only when commanded explicitly
