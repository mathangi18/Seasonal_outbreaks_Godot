extends Node

@export var target_pixels := 64.0
@export var margin := 0.0
@export var max_scale := 4.0
@export var min_scale := 0.05
@export var only_grouped := false
@export var group_name := "autoscale"

func _ready() -> void:
    scale_all_sprites()

func scale_all_sprites() -> void:
    if only_grouped:
        var nodes = get_tree().get_nodes_in_group(group_name)
        for n in nodes:
            if n is Sprite2D:
                _scale_sprite(n)
    else:
        var root = get_tree().get_current_scene()
        if not root:
            root = get_tree().get_root()
        _scan_and_scale(root)

func _scan_and_scale(node: Node) -> void:
    if node is Sprite2D:
        _scale_sprite(node)
    for child in node.get_children():
        if child is Node:
            _scan_and_scale(child)

func _scale_sprite(sprite: Sprite2D) -> void:
    if not sprite.texture:
        return
    var tex_size: Vector2 = sprite.texture.get_size()
    if tex_size.x <= 0 or tex_size.y <= 0:
        return
    var max_dim = max(tex_size.x, tex_size.y)
    var effective_target = max(1.0, target_pixels - margin)
    var factor = effective_target / max_dim
    factor = clamp(factor, min_scale, max_scale)
    sprite.scale = Vector2.ONE * factor
