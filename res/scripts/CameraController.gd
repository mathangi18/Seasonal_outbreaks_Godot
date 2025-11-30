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


    if Engine.is_editor_hint():
        return = Vector2(1.0, 1.0)
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



