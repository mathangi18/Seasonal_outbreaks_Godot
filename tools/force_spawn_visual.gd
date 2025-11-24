extends SceneTree

func _init():
    print("Force Spawn Visual Starting...")
    var main_path = "res://res/scenes/Main.tscn"
    if not ResourceLoader.exists(main_path):
        main_path = "res://res/res/scenes/Main.tscn"
    
    if ResourceLoader.exists(main_path):
        print("Loading Main scene from: ", main_path)
        var main = load(main_path).instantiate()
        root.add_child(main)
        print("MAIN: Spawn complete.")
        
        # Keep alive for a moment to allow rendering
        await create_timer(5.0).timeout
        quit()
    else:
        print("ERROR: Main.tscn not found!")
        quit()
