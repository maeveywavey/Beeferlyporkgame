extends Node
const CB = preload("res://scripts/actors/character_builder.gd")
func _ready() -> void:
	var libs := CB.animation_libraries()
	for k in libs:
		print(k, ": ", libs[k].get_animation_list())
	get_tree().quit()
