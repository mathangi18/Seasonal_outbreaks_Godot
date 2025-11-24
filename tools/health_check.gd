extends SceneTree
func _init():
    print("Running Health Check...")
    var ok = true
    # Check key scripts
    var scripts = [
        "res://res/scripts/Main.gd",
        "res://res/scripts/Patient.gd",
        "res://res/scripts/Facility.gd",
        "res://res/scripts/Ambulance.gd"
    ]
    for s in scripts:
        if not ResourceLoader.exists(s):
            print("MISSING SCRIPT: ", s)
            ok = false
    
    if ok: print("HEALTH_CHECK_OK")
    else: print("HEALTH_CHECK_FAILED")
    quit()
