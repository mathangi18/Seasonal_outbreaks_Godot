extends Node2D
class_name Ambulance
var capacity = 1
var passengers = []
func pickup(p:Node):
    if passengers.size() < capacity:
        passengers.append(p)
        p.get_parent().remove_child(p)
        add_child(p)
        p.position = Vector2.ZERO
        return true
    return false
func dropoff():
    for p in passengers:
        remove_child(p)
    passengers.clear()
