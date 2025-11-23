extends Node2D
const PatientScene = preload("res://res/scenes/Patient.tscn")
const FacilityScene = preload("res://res/scenes/Facility.tscn")
const AmbulanceScene = preload("res://res/scenes/Ambulance.tscn")
func _ready() -> void:
    randomize()
    for i in range(30):
        var p = PatientScene.instantiate()
        p.position = Vector2(randf()*800-400, randf()*600-300)
        add_child(p)
    for i in range(3):
        var f = FacilityScene.instantiate()
        f.position = Vector2(-300 + i*300, -50)
        add_child(f)
    for i in range(3):
        var a = AmbulanceScene.instantiate()
        a.position = Vector2(-200 + i*200, 150)
        add_child(a)
    print("MAIN: spawned demo entities")
