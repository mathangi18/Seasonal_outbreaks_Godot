extends Node
class_name ValidatorHelpers

static func exists(path:String) -> bool:
    return ResourceLoader.exists(path)