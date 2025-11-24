extends SceneTree
func _init():
    var ok = true
    var scenes = ["res://scenes/Main.tscn", "res://scenes/Patient.tscn", "res://scenes/Facility.tscn", "res://scenes/Ambulance.tscn"]
    for s in scenes:
        if not ResourceLoader.exists(s): ok = false
    if ok: print("HEALTH_CHECK_OK")
    else: print("HEALTH_CHECK_FAILED")
    quit()
