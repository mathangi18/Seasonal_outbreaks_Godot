# node_watch_autoload.gd
# Tiny autoload script — drops into Output when the project runs.
extends Node

func _ready():
    # prints a single number once, minimal noise
    print("\n=== NODE WATCH (single print) ===")
    print(get_tree().get_node_count())
    print("=== END NODE WATCH ===\n")
