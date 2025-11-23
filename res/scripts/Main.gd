extends Node
var patient_scene = preload('res://res/scenes/Patient.tscn')
var facility_scene = preload('res://res/scenes/Facility.tscn')
var ambulance_scene = preload('res://res/scenes/Ambulance.tscn')
var simulation_engine: SimulationEngine
var camera: CameraController
var hud: HUD

func _ready():
    print('Main: Initializing simulation...')
    simulation_engine = SimulationEngine.new()
    simulation_engine.name = 'SimulationEngine'
    simulation_engine.add_to_group('simulation')
    add_child(simulation_engine)
    
    camera = CameraController.new()
    camera.name = 'Camera'
    camera.position = Vector2(512, 384)
    add_child(camera)
    
    hud = HUD.new()
    hud.name = 'HUD'
    hud.engine = simulation_engine
    add_child(hud)
    
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    
    for i in range(3):
        var f = facility_scene.instantiate()
        f.position = Vector2(rng.randf_range(100, 900), rng.randf_range(100, 600))
        add_child(f)
        
    for i in range(100):
        var p = patient_scene.instantiate()
        p.position = Vector2(rng.randf_range(50, 974), rng.randf_range(50, 718))
        add_child(p)
        
    for i in range(3):
        var a = ambulance_scene.instantiate()
        a.position = Vector2(rng.randf_range(100, 900), rng.randf_range(100, 600))
        add_child(a)
        
    simulation_engine.start_simulation()
    print('Main: Simulation started with 100 patients, 3 facilities, 3 ambulances')
