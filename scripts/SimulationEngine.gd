# SimulationEngine
# Manages the core simulation loop, entity spawning, and infection logic.
# Background: Simulates a seasonal outbreak with S-E-I-R model.
# If you need to render more assets, see migration/render_requests.json.
# SimulationEngine
# Manages the core simulation loop, entity spawning (patients, facilities), and infection logic.
# This script drives the tick-based simulation and updates the state of all agents.
# If you need to render more assets, see migration/render_requests.json.
﻿extends Node
class_name SimulationEngine

# Core simulation parameters
@export var initial_population: int = 100
@export var facility_count: int = 3
@export var ambulance_count: int = 2
@export var infection_radius: float = 30.0
@export var infection_prob: float = 0.3
@export var recovery_chance: float = 0.05

# State tracking
var patients: Array = []
var facilities: Array = []
var ambulances: Array = []
var current_tick: int = 0
var is_running: bool = false

# Audio players
var sfx_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

# Resources
var patient_scene = preload("res://scenes/patient.tscn")
var facility_scene = preload("res://scenes/facility.tscn")
var ambulance_scene = preload("res://scenes/ambulance.tscn")

signal tick_updated(tick)

func _ready():
    # Setup audio players
    sfx_player = AudioStreamPlayer.new()
    add_child(sfx_player)
    
    ambient_player = AudioStreamPlayer.new()
    add_child(ambient_player)
    
    # Load ambient background if available
    if ResourceLoader.exists("res://res/assets/sounds/ambient_bg.ogg"):
        ambient_player.stream = ResourceLoader.load("res://res/assets/sounds/ambient_bg.ogg")
        ambient_player.autoplay = false
        ambient_player.play()

func play_infection_sound():
    if ResourceLoader.exists("res://res/assets/sounds/infect.ogg"):
        sfx_player.stream = ResourceLoader.load("res://res/assets/sounds/infect.ogg")
        sfx_player.play()

func start_simulation():
    if is_running: return
    is_running = true
    
    spawn_world_entities()
    
    var timer = Timer.new()
    timer.wait_time = 0.5 # 2 ticks per second
    timer.timeout.connect(_on_tick)
    add_child(timer)
    timer.start()
    print("Simulation started.")

func spawn_world_entities():
    var world = get_parent().get_node_or_null("World")
    if not world:
        print("Error: World node not found")
        return

    # Clear existing
    for c in world.get_children():
        c.queue_free()
    patients.clear()
    facilities.clear()
    ambulances.clear()
    
    # Spawn Facilities
    for i in range(facility_count):
        var f = facility_scene.instantiate()
        f.position = Vector2(randf_range(50, UIScale.world_width-50), randf_range(50, UIScale.world_height-50))
        world.add_child(f)
        facilities.append(f)
        
    # Spawn Ambulances
    for i in range(ambulance_count):
        var a = ambulance_scene.instantiate()
        a.position = Vector2(50, 50) + Vector2(i*40, 0)
        world.add_child(a)
        ambulances.append(a)
        
    # Spawn Patients
    for i in range(initial_population):
        var p = patient_scene.instantiate()
        p.position = Vector2(randf_range(20, UIScale.world_width-20), randf_range(20, UIScale.world_height-20))
        world.add_child(p)
        patients.append(p)
        
    # Infect initial patient
    if patients.size() > 0:
        patients[0].infect()

func _on_tick():
    if not is_running: return
    current_tick += 1
    tick_updated.emit(current_tick)
    
    # 1. Update Patients (Movement, State Timers)
    for p in patients:
        if p.has_method("sim_tick"):
            p.sim_tick(current_tick)
            
    # 2. Infection Spread
    # Optimization: Spatial grid would be better, but O(N^2) is fine for N=100
    for p in patients:
        if p.state == Patient.State.INFECTIOUS or p.state == Patient.State.SYMPTOMATIC:
            for other in patients:
                if other.state == Patient.State.SUSCEPTIBLE:
                    if p.position.distance_to(other.position) < infection_radius:
                        if randf() < infection_prob:
                            other.infect()
                            play_infection_sound()
                            
    # 3. Facilities Logic
    for f in facilities:
        if f.has_method("tick_service"):
            f.tick_service()
            
    # 4. Ambulance Dispatch
    # Simple strategy: Find first symptomatic patient not being attended
    for p in patients:
        if p.state == Patient.State.SYMPTOMATIC and p.visible and not p.is_being_attended:
            var ambulance = get_idle_ambulance()
            if ambulance:
                var facility = get_available_facility()
                if facility:
                    ambulance.dispatch(p, facility)
                    p.is_being_attended = true

func get_idle_ambulance():
    for a in ambulances:
        if a.state == Ambulance.State.IDLE:
            return a
    return null

func get_available_facility():
    # Return facility with least queue or just random
    if facilities.is_empty(): return null
    return facilities[0] # Simplification for now

func get_counts() -> Dictionary:
    var counts = {"S":0, "E":0, "I":0, "Sym":0, "R":0, "H":0}
    for p in patients:
        match p.state:
            Patient.State.SUSCEPTIBLE: counts.S += 1
            Patient.State.EXPOSED: counts.E += 1
            Patient.State.INFECTIOUS: counts.I += 1
            Patient.State.SYMPTOMATIC: counts.Sym += 1
            Patient.State.RECOVERED: counts.R += 1
            Patient.State.HOSPITALIZED: counts.H += 1
    counts["Tick"] = current_tick
    return counts
