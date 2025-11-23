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
