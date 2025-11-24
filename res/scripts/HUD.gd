extends CanvasLayer
class_name HUD
var engine:SimulationEngine = null
var label: Label
func _ready():
    label = Label.new()
    add_child(label)
    label.text = 'HUD: waiting for engine...'
    set_process(true)
func _process(delta):
    if engine == null:
        for n in get_tree().get_nodes_in_group('simulation'):
            if n is SimulationEngine:
                engine = n
                label.text = 'HUD: connected'
                break
