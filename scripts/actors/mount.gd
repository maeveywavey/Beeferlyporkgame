extends RefCounted
## Rigged, animated mounts from Quaternius's CC0 animal pack, repainted and
## dressed as the creatures of the setting:
##   ostrich — the Earth Kingdom's ostrich horse (horse body, crest and plume)
##   rhino   — the Fire Nation's komodo rhino (an armoured, horned triceratops
##             from Quaternius's CC0 dinosaur pack, painted slate green)
##   bison   — an Air Nomad sky bison (huge, white, brown arrow, big saddle)
## The source animals are real-world species; the dressing makes them read as
## the show's hybrids at a distance. See docs/03_playtests.md for the caveat.

const Acc = preload("res://scripts/actors/accessories.gd")

const KINDS := {
	"ostrich": {"src": "Horse", "tint": Color(0.86, 0.68, 0.46), "height": 1.5, "saddle": Color(0.3, 0.45, 0.22), "trim": Color(0.85, 0.7, 0.3), "lum": Vector2(0.35, 1.15)},
	"rhino": {"src": "Triceratops", "anim": "Triceratops_", "tint": Color(0.8, 0.84, 0.74), "height": 1.45, "saddle": Color(0.55, 0.1, 0.07), "trim": Color(0.25, 0.22, 0.22), "lum": Vector2(0.5, 1.1)},
	"bison": {"src": "Cow", "tint": Color(1.0, 0.98, 0.92), "height": 3.4, "saddle": Color(0.62, 0.36, 0.14), "trim": Color(0.95, 0.62, 0.15), "lum": Vector2(0.95, 1.0)},
}

static var _scenes := {}

static func kind_for_item(item_id: String) -> String:
	match Data.item(item_id).get("look", ""):
		"rhino": return "rhino"
		"ostrich": return "ostrich"
	return "ostrich"

## Returns {"root", "anim", "seat"}; the animal faces +Z.
static func build(kind: String) -> Dictionary:
	var k: Dictionary = KINDS.get(kind, KINDS.ostrich)
	var ps: PackedScene = _scenes.get(k.src)
	if ps == null:
		ps = load("res://assets/animals/%s.fbx" % k.src)
		_scenes[k.src] = ps
	var inst: Node3D = ps.instantiate()
	var skel: Skeleton3D = inst.find_children("*", "Skeleton3D", true, false)[0]
	var arm: Node3D = skel.get_parent()
	var anim: AnimationPlayer = inst.find_children("*", "AnimationPlayer", true, false)[0]
	var M: Transform3D = arm.transform * skel.transform
	var torso := skel.find_bone("Torso")
	var torso_y: float = (M * skel.get_bone_global_rest(torso).origin).y
	var s: float = k.height / maxf(0.001, torso_y)
	inst.scale = Vector3.ONE * s
	_paint(inst, k.tint, k.lum)
	var root := Node3D.new()
	root.add_child(inst)
	var ctx := {"skel": skel, "M": M, "s": s}
	var bone_m := func(b: String) -> Vector3: return M * skel.get_bone_global_rest(skel.find_bone(b)).origin * s
	var h: float = k.height
	# saddle and blanket on the torso
	var torso_p: Vector3 = bone_m.call("Torso")
	var w := 0.5 if kind != "bison" else 1.6
	_attach(ctx, "Torso", Acc.box(Vector3(w, 0.1, w * 1.3), k.saddle, Transform3D(Basis(), torso_p + Vector3(0, 0.14 * (h / 1.5), 0))))
	_attach(ctx, "Torso", Acc.box(Vector3(w * 1.25, h * 0.28, w * 0.9), k.saddle.darkened(0.25), Transform3D(Basis(), torso_p + Vector3(0, -h * 0.05, 0))))
	_attach(ctx, "Torso", Acc.box(Vector3(w * 1.27, 0.06, w * 0.92), k.trim, Transform3D(Basis(), torso_p + Vector3(0, -h * 0.19, 0))))
	var head_p: Vector3 = bone_m.call("Head")
	var head_end: Vector3 = bone_m.call("Head_end")
	var fwd: Vector3 = (head_end - head_p).normalized()
	match kind:
		"rhino":
			# armoured plates along the back, lacquered Fire Nation red at the edges
			for bn in ["Shoulders", "Torso", "Hips"]:
				var bp: Vector3 = bone_m.call(bn)
				_attach(ctx, bn, Acc.node(Acc.shell(0.36, 0.16, 150.0, 0.02, 10), Color(0.3, 0.32, 0.29), Transform3D(Basis(), bp + Vector3(0, 0.16, 0))))
		"ostrich":
			# a feathered crest and a plumed tail, Earth Kingdom tack
			for i in 3:
				var a := -0.4 + i * 0.4
				_attach(ctx, "Head", Acc.box(Vector3(0.03, 0.26, 0.08), Color(0.32, 0.5, 0.25) if i != 1 else Color(0.85, 0.7, 0.3),
					Transform3D(Basis(Vector3.RIGHT, -0.6).rotated(Vector3.UP, a * 0.3), head_p + Vector3(a * 0.05, 0.22, -0.05))))
			var tail_p: Vector3 = bone_m.call("Tail1")
			for i in 4:
				_attach(ctx, "Tail1", Acc.box(Vector3(0.05, 0.4, 0.04), Color(0.35, 0.28, 0.2), Transform3D(Basis(Vector3.RIGHT, 0.6 + i * 0.15).rotated(Vector3.UP, (i - 1.5) * 0.3), tail_p + Vector3(0, 0.1, -0.1))))
		"bison":
			# the brown arrow running from the brow down the back
			var pts := ["Head", "Neck", "Shoulders", "Torso", "Hips", "Back"]
			for bn in pts:
				var bp2: Vector3 = bone_m.call(bn)
				_attach(ctx, bn, Acc.box(Vector3(0.5, 0.06, 0.7), Color(0.5, 0.32, 0.16), Transform3D(Basis(), bp2 + Vector3(0, h * 0.2, 0))))
			_attach(ctx, "Head", Acc.box(Vector3(1.0, 0.06, 0.25), Color(0.5, 0.32, 0.16), Transform3D(Basis(), head_p + Vector3(0, h * 0.2, fwd.z * 0.2))))
	var m := {"root": root, "anim": anim, "seat": torso_p.y + 0.18 * (h / 1.5), "kind": kind, "prefix": k.get("anim", "")}
	_play(m, "Idle", 1.0)
	return m

## Attach a piece authored in the mount's (scaled) model space to a bone.
static func _attach(ctx: Dictionary, bone: String, piece: Node3D) -> void:
	var skel: Skeleton3D = ctx.skel
	var bi := skel.find_bone(bone)
	var att := BoneAttachment3D.new()
	att.bone_name = bone
	skel.add_child(att)
	var s: float = ctx.s
	var M: Transform3D = ctx.M
	# piece transform in scaled model space -> skeleton space -> bone space
	var xf_model := Transform3D(piece.transform.basis.scaled(Vector3.ONE / s), piece.transform.origin / s)
	var xf_skel: Transform3D = M.affine_inverse() * xf_model
	piece.transform = skel.get_bone_global_rest(bi).affine_inverse() * xf_skel
	att.add_child(piece)

static func _paint(n: Node, tint: Color, lum_range: Vector2) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		for i in mi.mesh.get_surface_count():
			var src: Material = mi.mesh.surface_get_material(i)
			var base := Color(0.6, 0.6, 0.6)
			if src is BaseMaterial3D:
				base = (src as BaseMaterial3D).albedo_color
			var lum := clampf(base.get_luminance() * 1.6, lum_range.x, lum_range.y)
			if base.get_luminance() < 0.12:
				lum = 0.35   # hooves and eyes stay dark
			var c := tint * lum
			c.a = 1.0
			mi.set_surface_override_material(i, Acc.mat(c, true, 0.2))
	for c in n.get_children():
		_paint(c, tint, lum_range)

static func _play(m: Dictionary, name: String, speed: float) -> void:
	var anim: AnimationPlayer = m.anim
	var full: String = "Armature|" + m.get("prefix", "") + name
	if not anim.has_animation(full):
		return
	if anim.current_animation != full:
		anim.get_animation(full).loop_mode = Animation.LOOP_LINEAR
		anim.play(full, 0.25)
	anim.speed_scale = speed

## Pick idle, walk or run from ground speed (m/s).
static func animate(m: Dictionary, speed: float) -> void:
	if speed < 0.3:
		_play(m, "Idle", 1.0)
	elif speed < 3.5:
		_play(m, "Walk", clampf(speed / 1.8, 0.6, 1.6))
	else:
		_play(m, "Run", clampf(speed / 9.0, 0.7, 1.5))

static func death_anim(m: Dictionary) -> String:
	return "Armature|" + m.get("prefix", "") + "Death"
