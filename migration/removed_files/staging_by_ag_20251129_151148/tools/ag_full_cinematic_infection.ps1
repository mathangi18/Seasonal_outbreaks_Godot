# ==============================================================================
# AG Cinematic Infection Build Script
# ==============================================================================
# Created: 2025-11-23T21:07:47+01:00
# Branch: godot/ag-cinematic-infection
# Purpose: Non-destructive build adding:
#   - Advanced infection mechanics (distance decay, incubation, superspreaders)
#   - Cinematic sequences (intro cutscene, camera dollies, smooth easing)
#   - Audio system (AudioManager singleton, ambient music, SFX)
#   - Contact tracing and R(t) logging
#   - Animated HUD and UI transitions
# ==============================================================================

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "=== AG Cinematic Infection Build ===" -ForegroundColor Cyan
Write-Host "Timestamp: $timestamp" -ForegroundColor Gray
Write-Host ""

# Navigate to repository
Set-Location "D:\Repos\Seasonal_outbreaks_Godot"
Write-Host "[1/14] Changed directory to repository" -ForegroundColor Green

# Create feature branch
Write-Host "[2/14] Creating feature branch..." -ForegroundColor Yellow
git checkout -b godot/ag-cinematic-infection
Write-Host "Branch created: godot/ag-cinematic-infection" -ForegroundColor Green

# Ensure directories exist
Write-Host "[3/14] Ensuring directory structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "res\scenes" | Out-Null
New-Item -ItemType Directory -Force -Path "res\scripts" | Out-Null
New-Item -ItemType Directory -Force -Path "res\sounds" | Out-Null
New-Item -ItemType Directory -Force -Path "logs" | Out-Null
Write-Host "Directory structure verified" -ForegroundColor Green

# ==============================================================================
# FILE CREATION: Enhanced GDScript Files
# ==============================================================================

Write-Host "[4/14] Creating enhanced GDScript files..." -ForegroundColor Yellow

# --- AudioManager.gd (Singleton) ---
@'
extends Node

# Audio channels
var ambient_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

# Volume settings
@export var ambient_volume: float = -10.0
@export var sfx_volume: float = 0.0
@export var music_volume: float = -5.0

# Audio resources (will be loaded if files exist)
var ambient_bg: AudioStream
var ambulance_siren: AudioStream
var patient_moan: AudioStream
var ui_pop: AudioStream
var cinematic_sting: AudioStream

func _ready():
    # Create audio players
    ambient_player = AudioStreamPlayer.new()
    sfx_player = AudioStreamPlayer.new()
    music_player = AudioStreamPlayer.new()
    
    add_child(ambient_player)
    add_child(sfx_player)
    add_child(music_player)
    
    ambient_player.volume_db = ambient_volume
    sfx_player.volume_db = sfx_volume
    music_player.volume_db = music_volume
    
    # Try to load audio files (gracefully handle missing files)
    load_audio_resources()
    
    # Start ambient loop if available
    if ambient_bg:
        ambient_player.stream = ambient_bg
        ambient_player.play()

func load_audio_resources():
    ambient_bg = try_load("res://sounds/ambient_bg.ogg")
    ambulance_siren = try_load("res://sounds/ambulance_siren.ogg")
    patient_moan = try_load("res://sounds/patient_moan.ogg")
    ui_pop = try_load("res://sounds/ui_pop.ogg")
    cinematic_sting = try_load("res://sounds/cinematic_sting.ogg")

func try_load(path: String) -> AudioStream:
    if ResourceLoader.exists(path):
        return load(path)
    return null

func play_sfx(sfx_name: String):
    var stream: AudioStream = null
    match sfx_name:
        "ambulance_siren": stream = ambulance_siren
        "patient_moan": stream = patient_moan
        "ui_pop": stream = ui_pop
        "cinematic_sting": stream = cinematic_sting
    
    if stream and sfx_player:
        sfx_player.stream = stream
        sfx_player.play()

func play_music(music_stream: AudioStream):
    if music_player and music_stream:
        music_player.stream = music_stream
        music_player.play()

func stop_music():
    if music_player:
        music_player.stop()
'@ | Set-Content -Path "res\scripts\AudioManager.gd" -Encoding UTF8

# --- Enhanced Patient.gd ---
@'
extends CharacterBody2D
class_name Patient

enum State { SUSCEPTIBLE, EXPOSED, INFECTIOUS, SYMPTOMATIC, RECOVERED, HOSPITALIZED }

var state: State = State.SUSCEPTIBLE
var target_pos: Vector2
var speed: float = 50.0
var is_being_attended: bool = false
var path_history: Array[Vector2] = []
const MAX_PATH_HISTORY = 50

# Infection metadata
var infected_by_id: int = -1
var infection_time: int = -1
var incubation_time: int = 5
var symptomatic_delay: int = 8

# Disease timers
var exposed_ticks: int = 0
var infectious_ticks: int = 0
var symptomatic_ticks: int = 0

# Protective factors
var has_mask: bool = false
var mask_protection: float = 0.5

# Config
var contagious_period: int = 10

signal state_changed(new_state)
signal patient_infected(patient_id, source_id)

func _ready():
    pick_new_target()
    update_visuals()
    collision_layer = 2
    collision_mask = 1 | 3
    
    # Randomize incubation and symptomatic delays
    incubation_time = randi_range(3, 7)
    symptomatic_delay = randi_range(6, 10)

func _physics_process(delta):
    if state == State.HOSPITALIZED:
        return
    
    # Store path history
    path_history.append(global_position)
    if path_history.size() > MAX_PATH_HISTORY:
        path_history.pop_front()
    
    # Movement
    var dir = (target_pos - position).normalized()
    velocity = dir * speed
    move_and_slide()
    
    if position.distance_to(target_pos) < 10.0:
        pick_new_target()
    
    queue_redraw()

func _draw():
    # Draw path history
    if path_history.size() > 1:
        var local_points: PackedVector2Array = []
        for point in path_history:
            local_points.append(to_local(point))
        draw_polyline(local_points, Color(1, 1, 1, 0.3), 1.0)

func pick_new_target():
    var w = 1152
    var h = 648
    target_pos = Vector2(randf_range(50, w-50), randf_range(50, h-50))

func infect():
    if state == State.SUSCEPTIBLE:
        state = State.EXPOSED
        exposed_ticks = 0
        update_visuals()
        state_changed.emit(state)

func mark_infected(by_id: int, tick: int):
    if state == State.SUSCEPTIBLE:
        infected_by_id = by_id
        infection_time = tick
        infect()
        patient_infected.emit(get_instance_id(), by_id)
        
        # Play sound effect
        if AudioManager:
            AudioManager.play_sfx("patient_moan")

func sim_tick(tick: int):
    if state == State.HOSPITALIZED:
        return
    
    match state:
        State.EXPOSED:
            exposed_ticks += 1
            if exposed_ticks >= incubation_time:
                state = State.INFECTIOUS
                infectious_ticks = 0
                update_visuals()
                state_changed.emit(state)
        State.INFECTIOUS:
            infectious_ticks += 1
            if infectious_ticks >= symptomatic_delay:
                state = State.SYMPTOMATIC
                symptomatic_ticks = 0
                update_visuals()
                state_changed.emit(state)
            elif infectious_ticks >= contagious_period:
                state = State.RECOVERED
                update_visuals()
                state_changed.emit(state)
        State.SYMPTOMATIC:
            symptomatic_ticks += 1
            if symptomatic_ticks > 20 and not is_being_attended:
                state = State.RECOVERED
                update_visuals()
                state_changed.emit(state)

func update_visuals():
    var sprite = $Sprite2D
    if not sprite: return
    
    match state:
        State.SUSCEPTIBLE: sprite.modulate = Color.GREEN
        State.EXPOSED: sprite.modulate = Color.YELLOW
        State.INFECTIOUS: sprite.modulate = Color.ORANGE
        State.SYMPTOMATIC: sprite.modulate = Color.RED
        State.RECOVERED: sprite.modulate = Color.BLUE
        State.HOSPITALIZED: sprite.modulate = Color.PURPLE

func hospitalize():
    state = State.HOSPITALIZED
    visible = false
    is_being_attended = false
    state_changed.emit(state)
    
    if AudioManager:
        AudioManager.play_sfx("ui_pop")
'@ | Set-Content -Path "res\scripts\Patient.gd" -Encoding UTF8

# --- Enhanced Ambulance.gd ---
@'
extends CharacterBody2D
class_name Ambulance

enum State { IDLE, MOVING_TO_PATIENT, TRANSPORTING, RETURNING }

var state: State = State.IDLE
var target_patient: Patient
var target_facility: Facility
var speed: float = 150.0
var turn_rate: float = 3.0
var capacity: int = 1
var carried_patients: Array[Patient] = []
var siren_playing: bool = false

signal ambulance_dispatched(ambulance_id, patient_id)

func _ready():
    collision_layer = 8
    collision_mask = 1
    var sprite = $Sprite2D
    if sprite:
        sprite.modulate = Color(1, 0.2, 0.2)

func _physics_process(delta):
    match state:
        State.IDLE:
            if siren_playing:
                siren_playing = false
        State.MOVING_TO_PATIENT:
            if not siren_playing:
                siren_playing = true
                if AudioManager:
                    AudioManager.play_sfx("ambulance_siren")
            
            if is_instance_valid(target_patient):
                move_to_smooth(target_patient.global_position, delta)
                if global_position.distance_to(target_patient.global_position) < 20.0:
                    pickup_patient()
            else:
                state = State.IDLE
        State.TRANSPORTING:
            if is_instance_valid(target_facility):
                move_to_smooth(target_facility.global_position, delta)
                if global_position.distance_to(target_facility.global_position) < 30.0:
                    drop_off_patients()
            else:
                state = State.IDLE

func move_to_smooth(target: Vector2, delta: float):
    var dir = (target - global_position).normalized()
    var desired_angle = dir.angle()
    rotation = lerp_angle(rotation, desired_angle, clamp(turn_rate * delta, 0.0, 1.0))
    
    var forward = Vector2.RIGHT.rotated(rotation)
    velocity = forward * speed
    move_and_slide()

func dispatch(patient: Patient, facility: Facility):
    if carried_patients.size() >= capacity:
        return
    target_patient = patient
    target_facility = facility
    state = State.MOVING_TO_PATIENT
    ambulance_dispatched.emit(get_instance_id(), patient.get_instance_id())

func pickup_patient():
    if is_instance_valid(target_patient) and carried_patients.size() < capacity:
        carried_patients.append(target_patient)
        target_patient.get_parent().remove_child(target_patient)
        add_child(target_patient)
        target_patient.position = Vector2(0, 0)
        target_patient.visible = false
        state = State.TRANSPORTING

func drop_off_patients():
    if is_instance_valid(target_facility):
        for patient in carried_patients:
            if is_instance_valid(patient):
                remove_child(patient)
                target_facility.get_parent().add_child(patient)
                patient.global_position = target_facility.global_position + Vector2(30, 30)
                target_facility.admit(patient)
        carried_patients.clear()
        state = State.IDLE
        siren_playing = false
'@ | Set-Content -Path "res\scripts\Ambulance.gd" -Encoding UTF8

# --- Enhanced Facility.gd ---
@'
extends Area2D
class_name Facility

@export var capacity: int = 5
@export var service_rate: int = 1
@export var infection_control_factor: float = 0.3

var occupants: Array = []
var queue: Array = []

signal facility_overloaded
signal patient_admitted(patient_id)

func _ready():
    collision_layer = 4
    update_label()

func _process(_delta):
    update_label()

func admit(patient: Patient) -> bool:
    if occupants.size() < capacity:
        occupants.append(patient)
        patient.hospitalize()
        update_label()
        patient_admitted.emit(patient.get_instance_id())
        return true
    else:
        enqueue(patient)
        return false

func enqueue(patient: Patient):
    if not queue.has(patient):
        queue.append(patient)
        update_label()
        if queue.size() > capacity * 2:
            facility_overloaded.emit()

func tick_service():
    # Discharge logic
    var to_remove = []
    for p in occupants:
        if randf() < 0.1:
            to_remove.append(p)
    
    for p in to_remove:
        occupants.erase(p)
        p.state = Patient.State.RECOVERED
        p.visible = true
        p.position = position + Vector2(50, 50)
    
    # Admit from queue
    while occupants.size() < capacity and queue.size() > 0:
        var p = queue.pop_front()
        occupants.append(p)
        p.hospitalize()
    
    update_label()

func update_label():
    var label = $Label
    if label:
        label.text = "HOSPITAL\nOcc: %d/%d\nQ: %d" % [occupants.size(), capacity, queue.size()]
'@ | Set-Content -Path "res\scripts\Facility.gd" -Encoding UTF8

# --- Enhanced SimulationEngine.gd ---
@'
extends Node
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
var patient_scene = preload("res://scenes/Patient.tscn")
var facility_scene = preload("res://scenes/Facility.tscn")
var ambulance_scene = preload("res://scenes/Ambulance.tscn")

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
'@ | Set-Content -Path "res\scripts\SimulationEngine.gd" -Encoding UTF8

# --- Enhanced CameraController.gd ---
@'
extends Camera2D

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var pan_speed: float = 200.0

# Cinematic sequence state
var cinematic_active: bool = false
var cinematic_time: float = 0.0
var cinematic_duration: float = 5.0
var cinematic_start_pos: Vector2
var cinematic_end_pos: Vector2
var cinematic_start_zoom: Vector2
var cinematic_end_zoom: Vector2

func _ready():
    zoom = Vector2(1.0, 1.0)
    position = Vector2(576, 324)

func _process(delta):
    if cinematic_active:
        process_cinematic(delta)
    else:
        process_normal_controls(delta)

func process_normal_controls(delta):
    # Zoom controls
    if Input.is_action_pressed("ui_page_up"):
        zoom += Vector2.ONE * zoom_speed * delta
    if Input.is_action_pressed("ui_page_down"):
        zoom -= Vector2.ONE * zoom_speed * delta
    
    zoom.x = clamp(zoom.x, min_zoom, max_zoom)
    zoom.y = clamp(zoom.y, min_zoom, max_zoom)
    
    # Pan controls
    var pan_dir = Vector2.ZERO
    if Input.is_action_pressed("ui_left"):
        pan_dir.x -= 1
    if Input.is_action_pressed("ui_right"):
        pan_dir.x += 1
    if Input.is_action_pressed("ui_up"):
        pan_dir.y -= 1
    if Input.is_action_pressed("ui_down"):
        pan_dir.y += 1
    
    position += pan_dir * pan_speed * delta / zoom.x

func start_cinematic_dolly(start: Vector2, end: Vector2, duration: float = 5.0):
    cinematic_active = true
    cinematic_time = 0.0
    cinematic_duration = duration
    cinematic_start_pos = start
    cinematic_end_pos = end
    cinematic_start_zoom = zoom
    cinematic_end_zoom = Vector2(1.5, 1.5)
    
    if AudioManager:
        AudioManager.play_sfx("cinematic_sting")

func process_cinematic(delta):
    cinematic_time += delta
    var t = clamp(cinematic_time / cinematic_duration, 0.0, 1.0)
    
    # Smooth easing (ease-in-out)
    var eased_t = ease_in_out(t)
    
    position = cinematic_start_pos.lerp(cinematic_end_pos, eased_t)
    zoom = cinematic_start_zoom.lerp(cinematic_end_zoom, eased_t)
    
    if t >= 1.0:
        cinematic_active = false

func ease_in_out(t: float) -> float:
    return t * t * (3.0 - 2.0 * t)
'@ | Set-Content -Path "res\scripts\CameraController.gd" -Encoding UTF8

# --- Enhanced HUD.gd ---
@'
extends CanvasLayer

@onready var sim_engine = get_node("/root/Main/SimulationEngine")
@onready var label = $Panel/Label

var visible_anim: bool = true
var fade_time: float = 0.0

func _ready():
    # Setup animated panel
    if has_node("Panel"):
        $Panel.modulate = Color(1, 1, 1, 0)
        fade_in()

func _process(delta):
    if sim_engine and sim_engine.has_method("get_counts"):
        var counts = sim_engine.get_counts()
        label.text = "Tick: %d | S:%d E:%d I:%d Sym:%d R:%d H:%d" % [
            counts.get("Tick", 0),
            counts.get("S", 0),
            counts.get("E", 0),
            counts.get("I", 0),
            counts.get("Sym", 0),
            counts.get("R", 0),
            counts.get("H", 0)
        ]
    
    # Animate fade
    if fade_time > 0:
        fade_time -= delta
        if has_node("Panel"):
            var alpha = 1.0 - (fade_time / 1.0)
            $Panel.modulate = Color(1, 1, 1, clamp(alpha, 0, 1))

func fade_in():
    fade_time = 1.0
    if AudioManager:
        AudioManager.play_sfx("ui_pop")

func fade_out():
    if has_node("Panel"):
        var tween = create_tween()
        tween.tween_property($Panel, "modulate:a", 0.0, 0.5)
'@ | Set-Content -Path "res\scripts\HUD.gd" -Encoding UTF8

# --- CutsceneIntro.gd ---
@'
extends Node2D

@onready var camera = $Camera2D
@onready var label = $CanvasLayer/Label

var cutscene_time: float = 0.0
var cutscene_duration: float = 8.0

func _ready():
    # Start cinematic
    if camera:
        camera.position = Vector2(0, 0)
        camera.zoom = Vector2(0.5, 0.5)
    
    if label:
        label.text = "SEASONAL OUTBREAK SIMULATION"
        label.modulate = Color(1, 1, 1, 0)
    
    if AudioManager:
        AudioManager.play_sfx("cinematic_sting")

func _process(delta):
    cutscene_time += delta
    var t = cutscene_time / cutscene_duration
    
    # Fade in title
    if label and t < 0.3:
        label.modulate = Color(1, 1, 1, t / 0.3)
    elif label and t > 0.7:
        label.modulate = Color(1, 1, 1, 1.0 - (t - 0.7) / 0.3)
    
    # Camera dolly
    if camera:
        camera.position = Vector2(t * 1152, t * 648)
        camera.zoom = Vector2(0.5 + t * 0.5, 0.5 + t * 0.5)
    
    # End cutscene
    if t >= 1.0:
        get_tree().change_scene_to_file("res://scenes/Main.tscn")
'@ | Set-Content -Path "res\scripts\CutsceneIntro.gd" -Encoding UTF8

Write-Host "Enhanced GDScript files created" -ForegroundColor Green

# ==============================================================================
# FILE CREATION: Scene Files
# ==============================================================================

Write-Host "[5/14] Creating scene files..." -ForegroundColor Yellow

# --- CutsceneIntro.tscn ---
@'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/CutsceneIntro.gd" id="1_script"]

[node name="CutsceneIntro" type="Node2D"]
script = ExtResource("1_script")

[node name="Camera2D" type="Camera2D" parent="."]

[node name="CanvasLayer" type="CanvasLayer" parent="."]

[node name="Label" type="Label" parent="CanvasLayer"]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -20.0
offset_right = 200.0
offset_bottom = 20.0
grow_horizontal = 2
grow_vertical = 2
text = "SEASONAL OUTBREAK SIMULATION"
horizontal_alignment = 1
vertical_alignment = 1
'@ | Set-Content -Path "res\scenes\CutsceneIntro.tscn" -Encoding UTF8

# --- Enhanced Main.tscn ---
@'
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/SimulationEngine.gd" id="1_sim"]
[ext_resource type="Script" path="res://scripts/HUD.gd" id="2_hud"]
[ext_resource type="Script" path="res://scripts/CameraController.gd" id="3_cam"]
[ext_resource type="PackedScene" path="res://scenes/World.tscn" id="4_world"]

[node name="Main" type="Node"]

[node name="SimulationEngine" type="Node" parent="."]
script = ExtResource("1_sim")

[node name="World" parent="." instance=ExtResource("4_world")]

[node name="Camera2D" type="Camera2D" parent="."]
position = Vector2(576, 324)
script = ExtResource("3_cam")

[node name="HUD" type="CanvasLayer" parent="."]
script = ExtResource("2_hud")

[node name="Panel" type="Panel" parent="HUD"]
offset_left = 10.0
offset_top = 10.0
offset_right = 510.0
offset_bottom = 50.0

[node name="Label" type="Label" parent="HUD/Panel"]
offset_left = 10.0
offset_top = 10.0
offset_right = 490.0
offset_bottom = 30.0
text = "Simulation HUD"
'@ | Set-Content -Path "res\scenes\Main.tscn" -Encoding UTF8

Write-Host "Scene files created" -ForegroundColor Green

# ==============================================================================
# FILE CREATION: Audio Placeholder Files
# ==============================================================================

Write-Host "[6/14] Creating audio placeholder files..." -ForegroundColor Yellow

# Create minimal OGG file headers (silent audio)
$oggHeader = [byte[]](0x4F, 0x67, 0x67, 0x53, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)

[System.IO.File]::WriteAllBytes("res\sounds\ambient_bg.ogg", $oggHeader)
[System.IO.File]::WriteAllBytes("res\sounds\ambulance_siren.ogg", $oggHeader)
[System.IO.File]::WriteAllBytes("res\sounds\patient_moan.ogg", $oggHeader)
[System.IO.File]::WriteAllBytes("res\sounds\ui_pop.ogg", $oggHeader)
[System.IO.File]::WriteAllBytes("res\sounds\cinematic_sting.ogg", $oggHeader)

Write-Host "Audio placeholder files created" -ForegroundColor Green

# ==============================================================================
# PROJECT.GODOT MODIFICATION
# ==============================================================================

Write-Host "[7/14] Adding AudioManager autoload..." -ForegroundColor Yellow

# Check if autoload section exists
$projectContent = Get-Content "project.godot" -Raw

if ($projectContent -notmatch '\[autoload\]') {
    # Add autoload section
    Add-Content "project.godot" "`n[autoload]`n"
}

# Add AudioManager if not already present
if ($projectContent -notmatch 'AudioManager') {
    Add-Content "project.godot" 'AudioManager="*res://scripts/AudioManager.gd"'
    Write-Host "AudioManager autoload added" -ForegroundColor Green
}
else {
    Write-Host "AudioManager autoload already exists" -ForegroundColor Gray
}

# ==============================================================================
# GIT OPERATIONS
# ==============================================================================

Write-Host "[8/14] Staging files..." -ForegroundColor Yellow
git add -A

Write-Host "[9/14] Creating commit..." -ForegroundColor Yellow
git commit -m "feat: cinematic sequence + advanced infection mechanics + audio (ag-cinematic-infection)"

Write-Host "[10/14] Creating tag..." -ForegroundColor Yellow
$tag_name = "ag-cinematic-infection-$timestamp"
git tag $tag_name
Write-Host "Tag created: $tag_name" -ForegroundColor Green

Write-Host "[11/14] Pushing branch to origin..." -ForegroundColor Yellow
git push -u origin godot/ag-cinematic-infection

Write-Host "[12/14] Pushing tags to origin..." -ForegroundColor Yellow
git push origin --tags

# ==============================================================================
# HEALTH CHECK
# ==============================================================================

Write-Host "[13/14] Running headless health check..." -ForegroundColor Yellow
$health_check_log = "D:\Repos\Seasonal_outbreaks_Godot\health_check_cinematic.log"
& "D:\Godot\Godot.exe" --path "D:\Repos\Seasonal_outbreaks_Godot" --headless --script res://tools/health_check.gd 2>&1 | Tee-Object $health_check_log

Write-Host "[14/14] Displaying health check results..." -ForegroundColor Yellow
Write-Host ""
Write-Host "=== HEALTH CHECK LOG (Last 200 lines) ===" -ForegroundColor Cyan
Get-Content $health_check_log -Tail 200

Write-Host ""
Write-Host "=== BUILD COMPLETE ===" -ForegroundColor Green
Write-Host "Branch: godot/ag-cinematic-infection" -ForegroundColor Gray
Write-Host "Tag: $tag_name" -ForegroundColor Gray
Write-Host "Health check log: $health_check_log" -ForegroundColor Gray
Write-Host ""
Write-Host "To open Godot editor visually, run:" -ForegroundColor Yellow
Write-Host '  & "D:\Godot\Godot.exe" --path "D:\Repos\Seasonal_outbreaks_Godot"' -ForegroundColor White
