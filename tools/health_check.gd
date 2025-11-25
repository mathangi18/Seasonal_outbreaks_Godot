# res://tools/health_check.gd
extends SceneTree

func _init():
    # Defer execution until the engine has finished starting
    call_deferred("_run_health_check")

func _run_health_check():
    var ok = true

    var scenes = [
        "res://scenes/Main.tscn",
        "res://scenes/main.tscn",
        "res://scenes/World.tscn"
    ]
    for s in scenes:
        if not ResourceLoader.exists(s):
            print("MISSING_SCENE:", s)
            ok = false
        else:
            var r = ResourceLoader.load(s)
            if r == null:
                print("FAILED_LOAD:", s)
                ok = false

    var scripts = [
        "res://res/scripts/SimulationEngine.gd",
        "res://res/scripts/Patient.gd",
        "res://res/scripts/Facility.gd",
        "res://res/scripts/Ambulance.gd",
        "res://res/scripts/HUD.gd"
    ]
    for sc in scripts:
        if not ResourceLoader.exists(sc):
            print("MISSING_SCRIPT:", sc)
            ok = false

    if ok:
        print("HEALTH_CHECK_OK")
    else:
        print("HEALTH_CHECK_FAILED")

    # Graceful exit: quit the engine process
    quit()
