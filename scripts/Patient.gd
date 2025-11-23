extends CharacterBody2D
class_name Patient

enum State { SUSCEPTIBLE, EXPOSED, INFECTIOUS, SYMPTOMATIC, RECOVERED, HOSPITALIZED }

var state: State = State.SUSCEPTIBLE
var target_pos: Vector2
var speed: float = 10.0
var is_being_attended: bool = false # Added for ambulance dispatch logic

# Timers
var exposed_ticks: int = 0
var infectious_ticks: int = 0
var symptomatic_ticks: int = 0

# Config
var incubation_period: int = 5
var contagious_period: int = 10
var symptom_onset: int = 8 

signal state_changed(new_state)

func _ready():
    speed = UIScale.PATIENT_BASE_SPEED * 10.0 
    pick_new_target()
    update_visuals()
    
    collision_layer = 2 
    collision_mask = 1 | 3 

func _physics_process(delta):
    if state == State.HOSPITALIZED:
        return
        
    var dir = (target_pos - position).normalized()
    velocity = dir * UIScale.ss(speed)
    move_and_slide()
    
    if position.distance_to(target_pos) < 10.0:
        pick_new_target()

func pick_new_target():
    var w = UIScale.world_width 
    var h = UIScale.world_height
    target_pos = Vector2(randf_range(0, w), randf_range(0, h))

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
            if symptomatic_ticks > 20 and not is_being_attended: # Only recover if not waiting for ambulance? Or keep simple
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
        State.HOSPITALIZED: visible = false

func hospitalize():
    state = State.HOSPITALIZED
    visible = false
    is_being_attended = false # Reset
    state_changed.emit(state)
