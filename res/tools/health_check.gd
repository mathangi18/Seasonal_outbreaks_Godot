# res://tools/health_check.gd
extends Node

func _ready():
    var ok = true
    # minimal scene/script list to validate — we'll expand this later
    var scenes = [
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
        "res://scripts/game.gd",
        "res://scripts/player.gd"
    ]
    for sc in scripts:
        if not ResourceLoader.exists(sc):
            print("MISSING_SCRIPT:", sc)
            ok = false

    if ok:
        print("HEALTH_CHECK_OK")
    else:
        print("HEALTH_CHECK_FAILED")

    # exit cleanly in headless runs
    get_tree().quit()
