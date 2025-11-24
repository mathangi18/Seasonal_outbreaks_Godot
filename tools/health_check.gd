extends SceneTree
func _init():
    print("Running Health Check...")
    var ok = true
    var scenes = ["res://scenes/Main.tscn", "res://scenes/Patient.tscn", "res://scenes/Facility.tscn", "res://scenes/Ambulance.tscn"]
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
