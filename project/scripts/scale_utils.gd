extends Node
class_name ScaleUtils

static func uniform_scale(base: Vector2, target: Vector2) -> float:
    if base.x <= 0 or base.y <= 0: return 1.0
    return min(target.x/base.x, target.y/base.y)