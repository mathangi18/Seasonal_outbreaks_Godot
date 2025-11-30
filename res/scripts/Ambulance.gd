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


    if Engine.is_editor_hint():
        return = 8
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



