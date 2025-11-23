extends Node2D
class_name Facility
var capacity = 10
var occupied = 0
func admit_patient(p):
    if occupied < capacity:
        occupied += 1
        return true
    return false
func discharge_patient():
    if occupied > 0: occupied -= 1
