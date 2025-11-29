# ==============================================================================
# AG Full Visual Ambulance Build Script
# ==============================================================================
# Created: 2025-11-23T20:54:37+01:00
# Branch: godot/ag-visual-ambulance-full
# Purpose: Non-destructive build of complete visual simulation with:
#   - Visual patients with path history
#   - Smooth-turning ambulances with capacity
#   - Facility labels showing queue counts
#   - HUD with live statistics
#   - Camera controller with zoom
#   - Enhanced infection mechanics with R(t) logging
# ==============================================================================

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "=== AG Full Visual Ambulance Build ===" -ForegroundColor Cyan
Write-Host "Timestamp: $timestamp" -ForegroundColor Gray
Write-Host ""

# Navigate to repository
Set-Location "D:\Repos\Seasonal_outbreaks_Godot"
Write-Host "[1/12] Changed directory to repository" -ForegroundColor Green

# Create feature branch
Write-Host "[2/12] Creating feature branch..." -ForegroundColor Yellow
git checkout -b godot/ag-visual-ambulance-full
Write-Host "Branch created: godot/ag-visual-ambulance-full" -ForegroundColor Green

# Ensure directories exist
Write-Host "[3/12] Ensuring directory structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "res\scenes" | Out-Null
New-Item -ItemType Directory -Force -Path "res\scripts" | Out-Null
New-Item -ItemType Directory -Force -Path "res\assets" | Out-Null
New-Item -ItemType Directory -Force -Path "logs" | Out-Null
New-Item -ItemType Directory -Force -Path "tools" | Out-Null
Write-Host "Directory structure verified" -ForegroundColor Green

# ==============================================================================
# FILE CREATION: GDScript Files
# ==============================================================================

Write-Host "[4/12] Creating GDScript files..." -ForegroundColor Yellow

# --- Patient.gd ---
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

# Disease timers
var exposed_ticks: int = 0
var infectious_ticks: int = 0
var symptomatic_ticks: int = 0

# Config
var incubation_period: int = 5
var contagious_period: int = 10
var symptom_onset: int = 8

signal state_changed(new_state)

func _ready():
    pick_new_target()
    update_visuals()
    collision_layer = 2
    collision_mask = 1 | 3

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

func sim_tick(tick: int):
    if state == State.HOSPITALIZED:
        return
    
    match state:
        State.EXPOSED:
            exposed_ticks += 1
            if exposed_ticks >= incubation_period:
                state = State.INFECTIOUS
                infectious_ticks = 0
                update_visuals()
                state_changed.emit(state)
        State.INFECTIOUS:
            infectious_ticks += 1
            if infectious_ticks >= symptom_onset:
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
'@ | Set-Content -Path "res\scripts\Patient.gd" -Encoding UTF8

# --- Ambulance.gd ---
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

func _ready():
    collision_layer = 8
    collision_mask = 1
    var sprite = $Sprite2D
    if sprite:
        sprite.modulate = Color(1, 0.2, 0.2)

func _physics_process(delta):
    match state:
        State.IDLE:
            pass
        State.MOVING_TO_PATIENT:
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
'@ | Set-Content -Path "res\scripts\Ambulance.gd" -Encoding UTF8

# --- Facility.gd ---
@'
extends Area2D
class_name Facility

@export var capacity: int = 5
@export var service_rate: int = 1

var occupants: Array = []
var queue: Array = []

signal facility_overloaded

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

# --- HUD.gd ---
@'
extends CanvasLayer

@onready var sim_engine = get_node("/root/Main/SimulationEngine")

func _process(_delta):
    if sim_engine and sim_engine.has_method("get_counts"):
        var counts = sim_engine.get_counts()
        $Label.text = "Tick: %d | S:%d E:%d I:%d Sym:%d R:%d H:%d" % [
            counts.get("Tick", 0),
            counts.get("S", 0),
            counts.get("E", 0),
            counts.get("I", 0),
            counts.get("Sym", 0),
            counts.get("R", 0),
            counts.get("H", 0)
        ]
'@ | Set-Content -Path "res\scripts\HUD.gd" -Encoding UTF8

# --- CameraController.gd ---
@'
extends Camera2D

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0

func _ready():
    zoom = Vector2(1.0, 1.0)

func _process(delta):
    # Zoom controls
    if Input.is_action_pressed("ui_page_up"):
        zoom += Vector2.ONE * zoom_speed * delta
    if Input.is_action_pressed("ui_page_down"):
        zoom -= Vector2.ONE * zoom_speed * delta
    
    zoom.x = clamp(zoom.x, min_zoom, max_zoom)
    zoom.y = clamp(zoom.y, min_zoom, max_zoom)
'@ | Set-Content -Path "res\scripts\CameraController.gd" -Encoding UTF8

# --- SimulationEngine.gd ---
@'
extends Node
class_name SimulationEngine

# Core simulation parameters
@export var initial_population: int = 100
@export var facility_count: int = 3
@export var ambulance_count: int = 2
@export var infection_radius: float = 50.0
@export var base_transmission: float = 0.3

# State tracking
var patients: Array = []
var facilities: Array = []
var ambulances: Array = []
var current_tick: int = 0
var is_running: bool = false
var new_infections_this_tick: int = 0
var infection_log: Array = []

# Resources
var patient_scene = preload("res://scenes/Patient.tscn")
var facility_scene = preload("res://scenes/Facility.tscn")
var ambulance_scene = preload("res://scenes/Ambulance.tscn")

signal tick_updated(tick)

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
    print("Simulation started with visual enhancements")

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
    
    # Spawn Ambulances
    for i in range(ambulance_count):
        var a = ambulance_scene.instantiate()
        a.position = Vector2(100 + i * 50, 100)
        world.add_child(a)
        ambulances.append(a)
    
    # Spawn Patients
    for i in range(initial_population):
        var p = patient_scene.instantiate()
        p.position = Vector2(randf_range(50, 1100), randf_range(50, 600))
        world.add_child(p)
        patients.append(p)
    
    # Infect patient zero
    if patients.size() > 0:
        patients[0].infect()
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
    
    # Infection spread with distance-based probability
    for p in patients:
        if p.state == Patient.State.INFECTIOUS or p.state == Patient.State.SYMPTOMATIC:
            for other in patients:
                if other.state == Patient.State.SUSCEPTIBLE:
                    var dist = p.position.distance_to(other.position)
                    if dist < infection_radius:
                        var prob = base_transmission * (1.0 - dist / infection_radius)
                        if randf() < prob:
                            other.infect()
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

func get_idle_ambulance():
    for a in ambulances:
        if a.state == Ambulance.State.IDLE:
            return a
    return null

func get_available_facility():
    if facilities.is_empty(): return null
    # Return facility with smallest queue
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
    
    # Write to CSV every 50 ticks
    if current_tick % 50 == 0:
        save_infection_log()

func save_infection_log():
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
        print("Saved infection log to: ", file_path)
'@ | Set-Content -Path "res\scripts\SimulationEngine.gd" -Encoding UTF8

Write-Host "GDScript files created" -ForegroundColor Green

# ==============================================================================
# FILE CREATION: Scene Files
# ==============================================================================

Write-Host "[5/12] Creating scene files..." -ForegroundColor Yellow

# --- Patient.tscn ---
@'
[gd_scene load_steps=4 format=3 uid="uid://patient_visual"]

[ext_resource type="Script" path="res://scripts/Patient.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/patient.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="1"]
radius = 8.0

[node name="Patient" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 5
script = ExtResource("1_script")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("1")
'@ | Set-Content -Path "res\scenes\Patient.tscn" -Encoding UTF8

# --- Ambulance.tscn ---
@'
[gd_scene load_steps=4 format=3 uid="uid://ambulance_visual"]

[ext_resource type="Script" path="res://scripts/Ambulance.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/ambulance.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="1"]
size = Vector2(32, 16)

[node name="Ambulance" type="CharacterBody2D"]
collision_layer = 8
collision_mask = 1
script = ExtResource("1_script")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("1")
'@ | Set-Content -Path "res\scenes\Ambulance.tscn" -Encoding UTF8

# --- Facility.tscn ---
@'
[gd_scene load_steps=4 format=3 uid="uid://facility_visual"]

[ext_resource type="Script" path="res://scripts/Facility.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/facility.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="1"]
size = Vector2(64, 64)

[node name="Facility" type="Area2D"]
collision_layer = 4
collision_mask = 10
script = ExtResource("1_script")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("1")

[node name="Label" type="Label" parent="."]
offset_left = -40.0
offset_top = -60.0
offset_right = 40.0
offset_bottom = -30.0
text = "HOSPITAL"
horizontal_alignment = 1
'@ | Set-Content -Path "res\scenes\Facility.tscn" -Encoding UTF8

# --- Main.tscn ---
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

[node name="Label" type="Label" parent="HUD"]
offset_left = 10.0
offset_top = 10.0
offset_right = 500.0
offset_bottom = 40.0
text = "Simulation HUD"
'@ | Set-Content -Path "res\scenes\Main.tscn" -Encoding UTF8

Write-Host "Scene files created" -ForegroundColor Green

# ==============================================================================
# GIT OPERATIONS
# ==============================================================================

Write-Host "[6/12] Staging files..." -ForegroundColor Yellow
git add -A

Write-Host "[7/12] Creating commit..." -ForegroundColor Yellow
git commit -m "feat: visuals + ambulances + camera + infection R logging (ag-visual-ambulance-full)"

Write-Host "[8/12] Creating tag..." -ForegroundColor Yellow
$tag_name = "ag-visual-ambulance-full-$timestamp"
git tag $tag_name
Write-Host "Tag created: $tag_name" -ForegroundColor Green

Write-Host "[9/12] Pushing branch to origin..." -ForegroundColor Yellow
git push -u origin godot/ag-visual-ambulance-full

Write-Host "[10/12] Pushing tags to origin..." -ForegroundColor Yellow
git push origin --tags

# ==============================================================================
# HEALTH CHECK
# ==============================================================================

Write-Host "[11/12] Running headless health check..." -ForegroundColor Yellow
$health_check_log = "D:\Repos\Seasonal_outbreaks_Godot\health_check_visual.log"
& "D:\Godot\Godot.exe" --path "D:\Repos\Seasonal_outbreaks_Godot" --headless --script res://tools/health_check.gd 2>&1 | Tee-Object $health_check_log

Write-Host "[12/12] Displaying health check results..." -ForegroundColor Yellow
Write-Host ""
Write-Host "=== HEALTH CHECK LOG (Last 200 lines) ===" -ForegroundColor Cyan
Get-Content $health_check_log -Tail 200

Write-Host ""
Write-Host "=== BUILD COMPLETE ===" -ForegroundColor Green
Write-Host "Branch: godot/ag-visual-ambulance-full" -ForegroundColor Gray
Write-Host "Tag: $tag_name" -ForegroundColor Gray
Write-Host "Health check log: $health_check_log" -ForegroundColor Gray
Write-Host ""
Write-Host "To open Godot editor visually, run:" -ForegroundColor Yellow
Write-Host '  & "D:\Godot\Godot.exe" --path "D:\Repos\Seasonal_outbreaks_Godot"' -ForegroundColor White
