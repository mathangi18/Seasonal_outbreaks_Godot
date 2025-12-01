# validate_phase2_generated.gd  (Godot 4 compatible)
func _println(s):
    print(s)

func _ready():
    var scenes_dir := "res://phase2_output/scenes"
    var dir := Directory.new()
    var err := dir.open(scenes_dir)
    if err != OK:
        _println("[ERROR] Cannot open " + scenes_dir + " (check project path).")
        get_tree().quit(1)
        return
    dir.list_dir_begin(true, true)
    var fname := dir.get_next()
    var exit_code := 0
    while fname != "":
        if fname.to_lower().ends_with(".tscn"):
            var scene_path := scenes_dir.plus_file(fname)
            _println("CHECKING: " + scene_path)
            var packed := ResourceLoader.load(scene_path)
            if packed == null:
                _println("[LOAD_FAIL] " + scene_path)
                exit_code = 2
            else:
                var inst := null
                # Godot 4: instantiate() returns Node
                inst = packed.instantiate()
                if inst == null:
                    _println("[INSTANTIATE_FAIL] " + scene_path)
                    exit_code = 3
                else:
                    get_tree().root.add_child(inst)
                    # allow one frame to process _ready() and other deferred calls
                    await get_tree().process_frame
                    get_tree().root.remove_child(inst)
                    inst.queue_free()
                    _println("[OK] " + scene_path)
        fname = dir.get_next()
    dir.list_dir_end()
    if exit_code == 0:
        _println("VALIDATION COMPLETE: no scene load/instantiate errors detected.")
    else:
        _println("VALIDATION COMPLETE: errors detected. exit_code=" + str(exit_code))
    get_tree().quit(exit_code)
