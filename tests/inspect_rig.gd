extends Node
func _ready() -> void:
	for p in ["res://assets/characters/base/Superhero_Male_FullBody.gltf", "res://assets/characters/base/Superhero_Female_FullBody.gltf"]:
		var s: Node = load(p).instantiate()
		var sk: Skeleton3D = s.find_child("Skeleton3D", true, false)
		print(p.get_file(), " armature xform ", sk.get_parent().transform)
		for b in ["root", "pelvis", "spine_01", "spine_03", "neck_01", "Head", "clavicle_l", "upperarm_l", "lowerarm_l", "hand_l", "upperarm_r", "hand_r", "thigh_l", "calf_l", "foot_l", "ball_l"]:
			var i := sk.find_bone(b)
			var t := sk.get_bone_global_rest(i)
			print("  %-11s pos %s  ybasis %s" % [b, (sk.get_parent().transform * t.origin).snapped(Vector3(0.001,0.001,0.001)), t.basis.y.snapped(Vector3(0.01,0.01,0.01))])
		var head: MeshInstance3D = null
		for c in sk.get_children():
			if c is MeshInstance3D:
				print("  mesh ", c.name, " aabb ", c.get_aabb())
		s.free()
	get_tree().quit()
