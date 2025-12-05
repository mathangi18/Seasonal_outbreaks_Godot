extends Node
class_name ShutdownManager

func _notification(what):
    # NOTIFICATION_PREDELETE triggers when node is about to be removed; run cleanup then.
    if what == NOTIFICATION_PREDELETE:
        # ensure children are freed
        for c in get_tree().get_root().get_children():
            if c != self and is_instance_valid(c):
                c.call_deferred("queue_free")