extends Node2D

var patient_scene = preload("res://scenes/Patient.tscn")
var facility_scene = preload("res://scenes/Facility.tscn")
var ambulance_scene = preload("res://scenes/Ambulance.tscn")

func _ready():
    print("MAIN: Spawning entities...")
    randomize()
    
    for i in range(50):
        var p = patient_scene.instantiate()
        p.position = Vector2(randf() * 1000, randf() * 700)
        add_child(p)
        
    for i in range(3):
        var f = facility_scene.instantiate()
        f.position = Vector2(100 + i * 300, 200)
        add_child(f)
        
    for i in range(3):
        var a = ambulance_scene.instantiate()
        a.position = Vector2(100 + i * 300, 500)
        add_child(a)
        
    print("MAIN: Spawn complete.")
