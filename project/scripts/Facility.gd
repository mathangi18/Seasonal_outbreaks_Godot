extends Node2D
class_name Facility

@export var capacity := 10
var occupants := []

func admit(id:int) -> bool:
    if occupants.size() < capacity:
        occupants.append(id); return true
    return false

func discharge(id:int) -> bool:
    if id in occupants:
        occupants.erase(id); return true
    return false