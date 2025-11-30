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
@export var infection_radius: float = 50.0
@export var base_transmission: float = 0.3

# Advanced infection parameters
@export var superspreader_event_prob: float = 0.05
@export var superspreader_multiplier: float = 3.0
@export var mask_adoption_rate: float = 0.3

# State tracking
var patients: Array = []
var facilities: Array = []
var ambulances: Array = []
var current_tick: int = 0
var is_running: bool = false
var new_infections_this_tick: int = 0
var infection_log: Array = []
var infection_chain_log: Array = []

# Resources
var patient_scene = preload("res://scenes/patient.tscn")
var facility_scene = preload("res://scenes/facility.tscn")
var ambulance_scene = preload("res://scenes/ambulance.tscn")

# Signals
signal tick_updated(tick)
signal patient_infected(patient_id, source_id)
signal patient_admitted(patient_id)
signal ambulance_dispatched(ambulance_id, patient_id)

func _ready():
    pass

func start_simulation():
    if is_running: return
    is_running = true
    
    spawn_world_entities()
    
    var timer = Timer.new()
    timer.wait_time = 0.5
    timer.timeout.connect(_on_tick)
    add_child(timer)
    timer.start()
    print("Simulation started with cinematic infection mechanics")

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
        f.position = Vector2(randf_range(100, 1000), randf_range(100, 500))
        world.add_child(f)
        facilities.append(f)
        f.patient_admitted.connect(_on_patient_admitted)
    
    # Spawn Ambulances
    for i in range(ambulance_count):
        var a = ambulance_scene.instantiate()
        a.position = Vector2(100 + i * 50, 100)
        world.add_child(a)
        ambulances.append(a)
        a.ambulance_dispatched.connect(_on_ambulance_dispatched)
    
    # Spawn Patients
    for i in range(initial_population):
        var p = patient_scene.instantiate()
        p.position = Vector2(randf_range(50, 1100), randf_range(50, 600))
        
        # Apply mask adoption
        if randf() < mask_adoption_rate:
            p.has_mask = true
        
        world.add_child(p)
        patients.append(p)
        p.patient_infected.connect(_on_patient_infected_signal)
    
    # Infect patient zero
    if patients.size() > 0:
        patients[0].mark_infected(-1, 0)
        print("Patient zero infected")

func _on_tick():
    if not is_running: return
    current_tick += 1
    new_infections_this_tick = 0
    tick_updated.emit(current_tick)
    
    # Update patients
    for p in patients:
        if p.has_method("sim_tick"):
            p.sim_tick(current_tick)
    
    # Check for superspreader event
    var is_superspreader_event = randf() < superspreader_event_prob
    var transmission_multiplier = superspreader_multiplier if is_superspreader_event else 1.0
    
    # Infection spread with distance-based probability
    for p in patients:
        if p.state == Patient.State.INFECTIOUS or p.state == Patient.State.SYMPTOMATIC:
            for other in patients:
                if other.state == Patient.State.SUSCEPTIBLE:
                    var dist = p.position.distance_to(other.position)
                    if dist < infection_radius:
                        var prob = base_transmission * (1.0 - dist / infection_radius) * transmission_multiplier
                        
                        # Apply mask protection
                        if other.has_mask:
                            prob *= (1.0 - other.mask_protection)
                        
                        if randf() < prob:
                            other.mark_infected(p.get_instance_id(), current_tick)
                            new_infections_this_tick += 1
    
    # Facilities
    for f in facilities:
        if f.has_method("tick_service"):
            f.tick_service()
    
    # Ambulance dispatch
    for p in patients:
        if p.state == Patient.State.SYMPTOMATIC and p.visible and not p.is_being_attended:
            var ambulance = get_idle_ambulance()
            if ambulance:
                var facility = get_available_facility()
                if facility:
                    ambulance.dispatch(p, facility)
                    p.is_being_attended = true
    
    # Log R(t) every 10 ticks
    if current_tick % 10 == 0:
        log_reproduction_number()
    
    # Save infection chain every 50 ticks
    if current_tick % 50 == 0:
        save_infection_chain()

func get_idle_ambulance():
    for a in ambulances:
        if a.state == Ambulance.State.IDLE:
            return a
    return null

func get_available_facility():
    if facilities.is_empty(): return null
    var best = facilities[0]
    for f in facilities:
        if f.queue.size() < best.queue.size():
            best = f
    return best

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

func log_reproduction_number():
    var active_infectious = 0
    for p in patients:
        if p.state == Patient.State.INFECTIOUS or p.state == Patient.State.SYMPTOMATIC:
            active_infectious += 1
    
    var r_estimate = 0.0
    if active_infectious > 0:
        r_estimate = float(new_infections_this_tick) / float(active_infectious)
    
    infection_log.append({
        "tick": current_tick,
        "new_infections": new_infections_this_tick,
        "active_infectious": active_infectious,
        "r_estimate": r_estimate
    })
    
    if current_tick % 50 == 0:
        save_reproduction_log()

func save_reproduction_log():
    var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
    var file_path = "logs/reproduction_%s.csv" % timestamp
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_line("tick,new_infections,active_infectious,r_estimate")
        for entry in infection_log:
            file.store_line("%d,%d,%d,%.3f" % [
                entry.tick,
                entry.new_infections,
                entry.active_infectious,
                entry.r_estimate
            ])
        file.close()

func save_infection_chain():
    var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
    var file_path = "logs/infections_%s.csv" % timestamp
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_line("patient_id,infected_by_id,infection_time")
        for p in patients:
            if p.infected_by_id != -1:
                file.store_line("%d,%d,%d" % [
                    p.get_instance_id(),
                    p.infected_by_id,
                    p.infection_time
                ])
        file.close()

func _on_patient_infected_signal(patient_id: int, source_id: int):
    patient_infected.emit(patient_id, source_id)

func _on_patient_admitted(patient_id: int):
    patient_admitted.emit(patient_id)

func _on_ambulance_dispatched(ambulance_id: int, patient_id: int):
    ambulance_dispatched.emit(ambulance_id, patient_id)
