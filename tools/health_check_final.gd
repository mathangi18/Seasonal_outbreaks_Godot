extends SceneTree
func _init():
    var ok = true
    var scenes = ["res://res/res/scenes/Main.tscn", "res://res/res/scenes/Patient.tscn"]
    for s in scenes:
        if ResourceLoader.exists(s):
            var r = ResourceLoader.load(s)
            if r: print("LOAD OK: ", s)
            else: 
                print("LOAD FAIL: ", s)
                ok = false
        else:
            print("MISSING: ", s)
            ok = false
    
    if ok: print("HEALTH_CHECK_OK")
    else: print("HEALTH_CHECK_FAILED")
    quit()
