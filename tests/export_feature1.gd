extends SceneTree

func _init():
    var json_str = "{\"feature\":\"basic-simulation-start\",\"observed\":{\"infected\":0,\"recovered\":0,\"susceptible\":100}}"
    var abs_path = ProjectSettings.globalize_path("res://" + "tests/actual/feature1.json")
    var f = FileAccess.open(abs_path, FileAccess.WRITE)
    if f:
        # write raw UTF-8 bytes to avoid any string-type/parsing issues
        var b = json_str.to_utf8()
        f.store_buffer(b)
        f.close()
    # stop the main loop (we are the main loop)
    self.quit()