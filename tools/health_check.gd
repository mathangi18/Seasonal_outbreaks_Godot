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
        "res://scripts/Main.gd",
        "res://scripts/game.gd",
        "res://scripts/player.gd",
        "res://scripts/SimulationEngine.gd",
        "res://scripts/Patient.gd"
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
