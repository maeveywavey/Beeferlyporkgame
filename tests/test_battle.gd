extends Node
## Runs a full AI-vs-AI battle headlessly (player is AI controlled).
func _ready() -> void:
	var B = load("res://scripts/battle/battle.gd")
	B.autotest = true
	get_tree().change_scene_to_file.call_deferred("res://scenes/battle.tscn")
