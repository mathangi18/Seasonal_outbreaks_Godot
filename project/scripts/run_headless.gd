extends Node
class_name RunHeadless

func run_from_config(path: String) -> Dictionary:
    var out = {"success": false, "message": "", "result": null}
    var f = FileAccess.open(path, FileAccess.ModeFlags.READ)
    if f == null:
        out.message = "Missing config: " + path
        return out
    var raw = f.get_as_text()
    f.close()
    var parsed = JSON.parse_string(raw)
    if parsed.error != OK:
        out.message = "JSON parse error"
        return out
    var cfg: Dictionary = {}
    if typeof(parsed.result) == TYPE_DICTIONARY:
        cfg = parsed.result
    else:
        out.message = "Config root is not a Dictionary"
        return out
    var steps: int = 500
    if cfg.has("steps"):
        steps = int(cfg["steps"])
    var rng = RandomNumberGenerator.new()
    if cfg.has("seed"):
        rng.seed = int(cfg["seed"])
    else:
        rng.randomize()
    var EngineSC = preload("res://scripts/SimulationEngine.gd")
    var engine = EngineSC.new()
    add_child(engine)
    var res = {}
    if engine and engine.has_method("run_steps"):
        res = engine.run_steps(steps, rng)
    # ensure we free engine and allow deferred cleanup
    if is_instance_valid(engine):
        engine.queue_free()
    # give engine a frame to cleanup
    await get_tree().process_frame
    # call deferred full-tree cleanup via ShutdownManager if present
    if Engine.has_singleton("ShutdownManager"):
        var sm = Engine.get_singleton("ShutdownManager")
        if is_instance_valid(sm) and sm.has_method("_notification"):
            sm.call_deferred("_notification", 0)
    # final result
    out.success = true
    out.result = res
    out.message = "OK"
    return out