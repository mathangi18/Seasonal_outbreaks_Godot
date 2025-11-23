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
