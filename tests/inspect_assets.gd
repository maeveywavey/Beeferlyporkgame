extends Node
func _ready() -> void:
	for p in ["res://assets/characters/base/Superhero_Male_FullBody.gltf", "res://assets/characters/outfits/Male_Peasant.gltf", "res://assets/characters/hair/Hair_Long.gltf", "res://assets/animations/UAL1_Standard.glb"]:
		var s: Node = load(p).instantiate()
		print("== ", p)
		_dump(s, 0)
		var ap: AnimationPlayer = s.find_child("AnimationPlayer", true, false)
		if ap:
			print("  anim libs: ", ap.get_animation_library_list(), " count ", ap.get_animation_list().size())
			var a := ap.get_animation(ap.get_animation_list()[5])
			print("  sample track paths: ", a.track_get_path(0), " ", a.track_get_path(1), " len ", a.length)
		s.free()
	get_tree().quit()

func _dump(n: Node, d: int) -> void:
	if d > 4:
		return
	var extra := ""
	if n is MeshInstance3D:
		extra = " mesh=%s skel=%s surf=%d" % [n.mesh.resource_name if n.mesh else "", n.skeleton, n.mesh.get_surface_count() if n.mesh else 0]
	if n is Skeleton3D:
		extra = " bones=%d" % n.get_bone_count()
	print("  ".repeat(d + 1), n.name, " (", n.get_class(), ")", extra)
	for c in n.get_children():
		_dump(c, d + 1)
