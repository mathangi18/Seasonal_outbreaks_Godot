extends Node

var RunHeadlessSC := preload("res://scripts/run_headless.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var runner: Node = RunHeadlessSC.new()
    var result_dict: Dictionary = runner.run_from_config("res://test_config.json")

    if result_dict.has("result"):
        print("RUN_RESULT: ", JSON.stringify(result_dict["result"]))
    else:
        print("RUN_MESSAGE: ", str(result_dict.get("message", "NO_MESSAGE")))

    await get_tree().process_frame
    get_tree().quit()