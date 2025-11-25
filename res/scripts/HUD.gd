extends CanvasLayer

@onready var sim_engine = get_node("/root/Main/SimulationEngine")

func _process(_delta):
    if sim_engine and sim_engine.has_method("get_counts"):
        var counts = sim_engine.get_counts()
        $Label.text = "Tick: %d | S:%d E:%d I:%d Sym:%d R:%d H:%d" % [
            counts.get("Tick", 0),
            counts.get("S", 0),
            counts.get("E", 0),
            counts.get("I", 0),
            counts.get("Sym", 0),
            counts.get("R", 0),
            counts.get("H", 0)
        ]
