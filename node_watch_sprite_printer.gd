extends Node

var last_sprite_count := 0
var monitor_seconds := 6.0
var elapsed := 0.0

func _ready():
    print("\n=== SPRITE WATCH START ===")
    last_sprite_count = _count_sprites()
    print("Initial sprites:", last_sprite_count)

func _process(delta):
    elapsed += delta
    if elapsed > monitor_seconds:
        print("=== SPRITE WATCH END ===\n")
        queue_free()
        return
    var cur := _count_sprites()
    if cur > last_sprite_count:
        print("--- SPRITE INCREASE detected: now %s (was %s) ---" % [str(cur), str(last_sprite_count)])
        var paths := _get_sprite_paths(10)
        print("Example Sprite paths (up to 10):")
        for p in paths:
            print("  - %s" % [str(p)])
        for i in range(min(5, paths.size())):
            var node := get_node(paths[i])
            if node:
                var parent := node.get_parent()
                print("    parent:", parent.get_class(), parent.get_path())
        last_sprite_count = cur

func _count_sprites() -> int:
    return _count_sprites_rec(get_tree().get_root())

func _count_sprites_rec(n: Node) -> int:
    var cnt := 0
    if n is Sprite2D:
        cnt += 1
    for c in n.get_children():
        if c is Node:
            cnt += _count_sprites_rec(c)
    return cnt

func _get_sprite_paths(limit: int) -> Array:
    var out := []
    _collect_sprite_paths(get_tree().get_root(), out, limit)
    return out

func _collect_sprite_paths(n: Node, out: Array, limit: int) -> void:
    if out.size() >= limit:
        return
    if n is Sprite2D:
        out.append(n.get_path())
        if out.size() >= limit:
            return
    for c in n.get_children():
        if c is Node:
            _collect_sprite_paths(c, out, limit)
