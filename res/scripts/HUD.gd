extends CanvasLayer
class_name HUD

var engine:SimulationEngine = null
onready var label := Label.new()

func _ready():
    add_child(label)
    label.text = \"HUD: waiting for engine...\"
    set_process(true)

func _process(delta):
    if engine == null:
        var candidates = get_tree().get_nodes_in_group(\"simulation\") if has_method(\"get_tree\") else []
        for n in get_tree().get_nodes_in_group(\"simulation\"):
            if n is SimulationEngine:
                engine = n
                label.text = \"HUD: connected\"
                break
