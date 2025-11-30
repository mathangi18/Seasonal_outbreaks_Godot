extends Node
@tool
func _ready() -> void:
    var out = []
    var dir = DirAccess.open("res://")
    var scenes = []
    _collect_scenes(dir, "res://", scenes)
    for s in scenes:
        var result = {"scene": s, "loaded": false, "error": null, "load_ms": null}
        var t0 = OS.get_ticks_msec()
        var r = ResourceLoader.load(s)
        result["load_ms"] = OS.get_ticks_msec() - t0
        if r == null:
            result["error"] = "ResourceLoader returned null"
            out.append(result)
            continue
        var ok_instance = false
        var inst = null
        try:
            inst = r.instantiate()
            add_child(inst)
            get_tree().process_frame()
            get_tree().idle_frame()
            ok_instance = true
            inst.queue_free()
        except err:
            result["error"] = str(err)
        result["loaded"] = ok_instance
        out.append(result)
    var json = JSON.new()
    print(json.stringify(out))
    get_tree().quit(0)

func _collect_scenes(dir:DirAccess, base:String, out_arr:Array) -> void:
    dir.list_dir_begin()
    var fname = dir.get_next()
    while fname != "":
        if dir.current_is_dir():
            if fname != "." and fname != "..":
                var sub = DirAccess.open(base + fname + "/")
                _collect_scenes(sub, base + fname + "/", out_arr)
        else:
            if fname.ends_with(".tscn") or fname.ends_with(".scn"):
                out_arr.append(base + fname)
        fname = dir.get_next()
    dir.list_dir_end()
