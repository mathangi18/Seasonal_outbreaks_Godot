extends Node2D

var patient_scene = preload("res://res/scenes/Patient.tscn")
var facility_scene = preload("res://res/scenes/Facility.tscn")
var ambulance_scene = preload("res://res/scenes/Ambulance.tscn")

func _ready():
    print("Main: _ready called - spawning entities")
    var world = get_node("World")
    
    # Spawn SimulationEngine if it exists
    if ResourceLoader.exists("res://res/scripts/SimulationEngine.gd"):
        var sim_class = load("res://res/scripts/SimulationEngine.gd")
        var sim = sim_class.new()
        sim.name = "SimulationEngine"
        sim.add_to_group("simulation")
        add_child(sim)
        if sim.has_method("start_simulation"):
            sim.start_simulation()
            print("Main: SimulationEngine started")
            
    # Spawn HUD script if it exists
    if ResourceLoader.exists("res://res/scripts/HUD.gd"):
        var hud_node = get_node("HUD")
        hud_node.set_script(load("res://res/scripts/HUD.gd"))
        print("Main: HUD script attached")

    # Spawn Facilities
    for i in range(3):
        var f = facility_scene.instantiate()
        f.position = Vector2(100 + i*300, 200)
        world.add_child(f)
        
    # Spawn Patients
    for i in range(50):
        var p = patient_scene.instantiate()
        p.position = Vector2(randf() * 1000, randf() * 600)
        world.add_child(p)
        
    # Spawn Ambulances
    for i in range(3):
        var a = ambulance_scene.instantiate()
        a.position = Vector2(randf() * 1000, randf() * 600)
        world.add_child(a)
        
    print("Main: Spawning complete")
