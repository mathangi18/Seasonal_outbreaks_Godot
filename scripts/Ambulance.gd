extends CharacterBody2D
class_name Ambulance

enum State { IDLE, MOVING_TO_PATIENT, TRANSPORTING, RETURNING }

var state: State = State.IDLE
var target_patient: Patient
var target_facility: Facility
var speed: float = 150.0

# Audio
var siren_player: AudioStreamPlayer

func _ready():
    collision_layer = 8 
    collision_mask = 1 
    
    # Setup audio
    siren_player = AudioStreamPlayer.new()
    add_child(siren_player)
    if ResourceLoader.exists("res://res/assets/sounds/ambulance_siren.ogg"):
        siren_player.stream = ResourceLoader.load("res://res/assets/sounds/ambulance_siren.ogg")
    
    # Visuals
    var sprite = $Sprite2D
    if sprite:
        sprite.modulate = Color(1, 0, 0) # Red tint for ambulance

func _physics_process(delta):
    match state:
        State.IDLE:
            pass
        State.MOVING_TO_PATIENT:
            if is_instance_valid(target_patient):
                move_to(target_patient.position, delta)
                if position.distance_to(target_patient.position) < 10.0:
                    pickup_patient()
            else:
                state = State.IDLE
        State.TRANSPORTING:
            if is_instance_valid(target_facility):
                move_to(target_facility.position, delta)
                if position.distance_to(target_facility.position) < 10.0:
                    drop_off_patient()
            else:
                state = State.IDLE 

func move_to(target: Vector2, delta: float):
    var dir = (target - position).normalized()
    velocity = dir * speed
    move_and_slide()

func dispatch(patient: Patient, facility: Facility):
    target_patient = patient
    target_facility = facility
    state = State.MOVING_TO_PATIENT
    # Play siren
    if siren_player and siren_player.stream:
        siren_player.play()

func pickup_patient():
    if is_instance_valid(target_patient):
        target_patient.visible = false # Hide patient (inside ambulance)
        state = State.TRANSPORTING

func drop_off_patient():
    if is_instance_valid(target_facility) and is_instance_valid(target_patient):
        target_facility.admit(target_patient)
        state = State.IDLE


