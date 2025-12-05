extends MainLoop

var scene_tree := SceneTree.new()

func _initialize():
    # Start scene tree
    scene_tree.init()
    var runner_scene = load("res://tools/run_config_runner.tscn")
    var inst = runner_scene.instantiate()
    scene_tree.get_root().add_child(inst)
    return OK

func _process(delta):
    # Advance simulation
    var exit_code = scene_tree.iterate()
    if exit_code != OK:
        return exit_code
    return OK

func _finalize():
    scene_tree.finish()