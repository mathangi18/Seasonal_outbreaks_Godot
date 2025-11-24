extends Node2D
class_name Patient
enum State {SUSCEPTIBLE, EXPOSED, INFECTIOUS, SYMPTOMATIC, RECOVERED, HOSPITAL}
var state = State.SUSCEPTIBLE
var history = []
func _ready(): pass
func step(delta):
    history.append(position)
    if history.size() > 50: history.remove_at(0)
