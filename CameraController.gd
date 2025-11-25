extends Camera2D

@export var nodes_to_fit: Array[String] = [
    "res://scenes/Facility.tscn",
    "res://scenes/Ambulance.tscn",
    "res://scenes/Patient.tscn"
]
@export var margin := 200.0
@export var max_zoom := Vector2(1,1)
@export var min_zoom := Vector2(0.15,0.15)

func _ready() -> void:
    fit_nodes_to_view(nodes_to_fit)

func fit_nodes_to_view(scene_paths: Array[String]) -> void:
    var rect: Rect2 = Rect2()
    var first := true
    for spath in scene_paths:
        var inst_name := Path2Name(spath)
        var found = get_tree().get_root().find_node(inst_name, true, false)
        if found:
            var item_rect = _get_node_rect(found)
            if item_rect:
                if first:
                    rect = item_rect
                    first = false
                else:
                    rect = rect.merge(item_rect)

    if first:
        global_position = Vector2.ZERO
        zoom = max_zoom
        return

    global_position = rect.position + rect.size * 0.5

    var view_size = get_viewport_rect().size
    if view_size.x <= 0 or view_size.y <= 0:
        return

    var scale_x = (rect.size.x + margin*2.0) / view_size.x
    var scale_y = (rect.size.y + margin*2.0) / view_size.y
    var required_scale = max(scale_x, scale_y, 0.0001)
    var target_zoom = Vector2(required_scale, required_scale)

    target_zoom.x = clamp(target_zoom.x, min_zoom.x, max_zoom.x)
    target_zoom.y = clamp(target_zoom.y, min_zoom.y, max_zoom.y)
    zoom = target_zoom

func _get_node_rect(node: Node) -> Rect2:
    if node is CanvasItem:
        var ci := node as CanvasItem
        var sprite = ci.get_node_or_null("Sprite2D")
        if sprite and sprite is Sprite2D:
            var tex = sprite.texture
            if tex:
                var size = tex.get_size() * sprite.scale
                var pos = ci.global_position - size * 0.5
                return Rect2(pos, size)
        return Rect2(ci.global_position - Vector2(10,10), Vector2(20,20))
    return null

func Path2Name(path: String) -> String:
    return path.get_file().get_basename()
