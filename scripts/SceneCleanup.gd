extends Node
class_name SceneCleanup

# SceneCleanup should be attached to scene root nodes.
# On exit, it will free all child nodes (defensive cleanup to avoid leaked CanvasItems).
func _exit_tree():
    # Free children explicitly (deferred to avoid modifying tree during notifications)
    for c in get_children():
        if is_instance_valid(c):
            c.call_deferred("queue_free")