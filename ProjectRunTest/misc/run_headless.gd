extends SceneTree

var ticks := 200

func _initialize():
    for arg in OS.get_cmdline_args():
        if arg.begins_with("--ticks="):
            ticks = int(arg.split("=")[1])
    print("[HEADLESS] ticks=", ticks)

func _ready():
    print("[HEADLESS] Loading Main.tscn…")
    var main_scene := load("res://scenes/Main.tscn")
    if main_scene == null:
        print("[HEADLESS] ERROR: Cannot load Main.tscn")
        quit(1)
        return

    var inst := main_scene.instantiate()
    get_root().add_child(inst)

    var sim := inst.get_node_or_null("Simulation") \
            or inst.get_node_or_null("SimulationEngine")

    if sim == null:
        print("[HEADLESS] ERROR: Simulation node missing")
        quit(1)
        return

    print("[HEADLESS] Running ticks…")
    for i in ticks:
        if sim.has_method("_process"):
            sim._process(0.016)

    print("[HEADLESS] Done.")
    quit(0)
