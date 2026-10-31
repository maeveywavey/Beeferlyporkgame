extends RefCounted
## Hand-built PS1-budget garments, skinned to the rig: a tapered tunic, tube
## sleeves, tube trousers, boots, a belt and hands, in flat shaded colour from
## the culture's palette. A full outfit is 250-400 triangles (the CC0 outfits
## it replaces are 13,000-27,000). Everything is modelled in the rig's T-pose
## model space, read from the skeleton's rest pose, so it fits either body.
##
## "peasant": tunic to mid-hip, 3/4 sleeves, trousers, boots.
## "ranger": a longer coat with a skirt, full sleeves and bracers, a belt.

const Accessories = preload("res://scripts/actors/accessories.gd")

var skel: Skeleton3D
var surfaces := {}   # name -> SurfaceTool
var mats := {}       # name -> Material
var tri_count := 0
var mesh_name := "LowpolyOutfit"

func _surface(name: String, mat: Material) -> SurfaceTool:
	if not surfaces.has(name):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_smooth_group(-1)   # faceted, flat shaded
		surfaces[name] = st
		mats[name] = mat
	return surfaces[name]

func _bone(n: String) -> int:
	return skel.find_bone(n)

func _rest(n: String) -> Vector3:
	var i := _bone(n)
	return skel.get_bone_global_rest(i).origin if i >= 0 else Vector3.ZERO

## One vertex: position with up to two bones and a blend weight.
func _vert(st: SurfaceTool, p: Vector3, b0: int, b1: int, w1: float) -> void:
	st.set_bones(PackedInt32Array([b0, b1, 0, 0]))
	st.set_weights(PackedFloat32Array([1.0 - w1, w1, 0.0, 0.0]))
	st.add_vertex(p)

func _tri(st: SurfaceTool, a: Array, b: Array, c: Array, outward: Vector3) -> void:
	# Godot front faces wind clockwise: (c-a) x (b-a) must point outward
	var n := ((c[0] as Vector3) - (a[0] as Vector3)).cross((b[0] as Vector3) - (a[0] as Vector3))
	if n.dot(outward) < 0.0:
		var t := b
		b = c
		c = t
	for v in [a, b, c]:
		_vert(st, v[0], v[1], v[2], v[3])
	tri_count += 1

## A tube through rings: each ring {c, e1, e2, r1, r2, b0, b1, w}.
func tube(name: String, mat: Material, rings: Array, segs: int, cap_end: bool = false) -> void:
	var st := _surface(name, mat)
	var pts := []
	for r in rings:
		var ring := []
		for s in segs:
			var a := TAU * s / segs
			var p: Vector3 = r.c + r.e1 * cos(a) * r.r1 + r.e2 * sin(a) * r.r2
			ring.append([p, r.b0, r.b1, r.w])
		pts.append(ring)
	for k in rings.size() - 1:
		for s in segs:
			var s2 := (s + 1) % segs
			var a0: Array = pts[k][s]
			var a1: Array = pts[k][s2]
			var b0: Array = pts[k + 1][s]
			var b1: Array = pts[k + 1][s2]
			var out: Vector3 = ((a0[0] + a1[0] + b0[0] + b1[0]) * 0.25) - ((rings[k].c + rings[k + 1].c) * 0.5)
			_tri(st, a0, a1, b0, out)
			_tri(st, a1, b1, b0, out)
	if cap_end:
		var last: Array = pts[pts.size() - 1]
		var rc: Vector3 = rings[rings.size() - 1].c
		var ax: Vector3 = rings[rings.size() - 1].c - rings[rings.size() - 2].c
		for s in segs:
			var cen := [rc, rings[rings.size() - 1].b0, rings[rings.size() - 1].b1, rings[rings.size() - 1].w]
			_tri(st, cen, last[s], last[(s + 1) % segs], ax)

## An axis-aligned box on a bone (size in metres, centre in model space).
func box(name: String, mat: Material, centre: Vector3, size: Vector3, bone: int) -> void:
	var st := _surface(name, mat)
	var h := size * 0.5
	var corners := []
	for i in 8:
		corners.append(centre + Vector3(h.x * (1 if i & 1 else -1), h.y * (1 if i & 2 else -1), h.z * (1 if i & 4 else -1)))
	var faces := [[0, 1, 3, 2], [4, 5, 7, 6], [0, 1, 5, 4], [2, 3, 7, 6], [0, 2, 6, 4], [1, 3, 7, 5]]
	for f in faces:
		var c0: Vector3 = corners[f[0]]
		var c1: Vector3 = corners[f[1]]
		var c2: Vector3 = corners[f[2]]
		var c3: Vector3 = corners[f[3]]
		var out: Vector3 = (c0 + c1 + c2 + c3) * 0.25 - centre
		var v0 := [c0, bone, 0, 0.0]
		var v1 := [c1, bone, 0, 0.0]
		var v2 := [c2, bone, 0, 0.0]
		var v3 := [c3, bone, 0, 0.0]
		_tri(st, v0, v1, v2, out)
		_tri(st, v0, v2, v3, out)

func _ring(c: Vector3, e1: Vector3, e2: Vector3, r1: float, r2: float, b0: int, b1: int = 0, w: float = 0.0) -> Dictionary:
	return {"c": c, "e1": e1, "e2": e2, "r1": r1, "r2": r2, "b0": b0, "b1": b1, "w": w}

## Builds the outfit and returns the MeshInstance3D nodes (children of `skel`).
static func build(skel_: Skeleton3D, kind: String, sex: String, palette: Dictionary, skin: Color, tint: Color = Color.WHITE) -> Array:
	var o = load("res://scripts/actors/lowpoly_outfit.gd").new()
	o.skel = skel_
	o._make(kind, sex, palette, skin, tint)
	return o._commit()

func _skin_mat(c: Color) -> Material:
	var m: ShaderMaterial = Accessories.mat(c, true, 0.25, false).duplicate()
	m.set_shader_parameter("saturation", 1.0)
	return m

func _make(kind: String, sex: String, palette: Dictionary, skin: Color, tint: Color) -> void:
	var cloth: Material = Accessories.mat(palette.primary * tint)
	var trim: Material = Accessories.mat(palette.accent)
	var pants: Material = Accessories.mat(palette.secondary)
	var boots: Material = Accessories.mat(Color(0.2, 0.15, 0.11))
	var skinm := _skin_mat(skin)
	var fem := sex == "f"
	var X := Vector3.RIGHT
	var Y := Vector3.UP
	var Z := Vector3.BACK
	var pelvis := _bone("pelvis")
	var s1 := _bone("spine_01")
	var s2 := _bone("spine_02")
	var s3 := _bone("spine_03")
	var nk := _bone("neck_01")
	var hip_w := 0.172 * (1.1 if fem else 1.0)
	var sh_w := 0.2 * (0.92 if fem else 1.0)
	var ranger := kind == "ranger"
	# the tunic: hem to collar, eight-sided
	var hem := 0.80 if ranger else 0.88
	var zc := 0.012
	var torso := [
		_ring(Vector3(0, hem, zc), X, Z, hip_w * 1.05, 0.125, pelvis),
		_ring(Vector3(0, 1.0, zc), X, Z, hip_w, 0.118, pelvis, s1, 0.5),
		_ring(Vector3(0, 1.14, zc), X, Z, 0.145 * (0.95 if fem else 1.0), 0.106, s1, s2, 0.5),
		_ring(Vector3(0, 1.31, zc), X, Z, 0.185 * (0.9 if fem else 1.0), 0.118, s3),
		_ring(Vector3(0, 1.44, zc - 0.01), X, Z, sh_w * 1.0, 0.1, s3, nk, 0.25),
		_ring(Vector3(0, 1.505, zc - 0.02), X, Z, 0.066, 0.066, nk),
		_ring(Vector3(0, 1.545, zc - 0.02), X, Z, 0.062, 0.062, nk, _bone("Head"), 0.3),
	]
	tube("cloth", cloth, torso, 8)
	# the neck, so there is never a gap between jaw and collar
	tube("skin", skinm, [_ring(Vector3(0, 1.49, zc - 0.03), X, Z, 0.05, 0.05, nk), _ring(Vector3(0, 1.6, zc - 0.03), X, Z, 0.046, 0.046, _bone("Head"))], 6)
	if ranger:
		# the coat's skirt hangs from the hips, split by the thighs' bones
		var skirt := [
			_ring(Vector3(0, 0.99, zc), X, Z, hip_w * 1.08, 0.13, pelvis),
			_ring(Vector3(0, 0.80, zc), X, Z, hip_w * 1.35, 0.17, pelvis, _bone("thigh_l"), 0.4),
			_ring(Vector3(0, 0.66, zc), X, Z, hip_w * 1.55, 0.19, _bone("thigh_l"), _bone("thigh_r"), 0.5),
		]
		tube("cloth", cloth, skirt, 8)
	# the belt hugs the tunic at the waist (between the tunic's rings at 1.0 and 1.14)
	tube("trim", trim, [_ring(Vector3(0, 1.07, zc), X, Z, 0.158, 0.122, pelvis, s1, 0.7), _ring(Vector3(0, 1.115, zc), X, Z, 0.152, 0.118, s1)], 8)
	for side in ["l", "r"]:
		var sg := 1.0 if side == "l" else -1.0
		var ua := _bone("upperarm_" + side)
		var la := _bone("lowerarm_" + side)
		var hd := _bone("hand_" + side)
		var cl := _bone("clavicle_" + side)
		var p_ua := _rest("upperarm_" + side)
		var p_la := _rest("lowerarm_" + side)
		var p_hd := _rest("hand_" + side)
		var yy := p_ua.y
		var zz := p_ua.z
		# sleeve: shoulder to wrist (3/4 for peasants), six-sided
		var wrist_t := 0.82 if ranger else 0.6
		var wrist_x := lerpf(p_la.x, p_hd.x, wrist_t)
		var sleeve := [
			_ring(Vector3(sg * 0.17, yy, zz), Y, Z, 0.062, 0.062, cl, ua, 0.6),
			_ring(Vector3(sg * (absf(p_ua.x) + 0.1), yy, zz), Y, Z, 0.052, 0.052, ua),
			_ring(Vector3(p_la.x, yy, p_la.z), Y, Z, 0.047, 0.047, ua, la, 0.5),
			_ring(Vector3(sg * absf(wrist_x), yy, lerpf(p_la.z, p_hd.z, wrist_t)), Y, Z, 0.039, 0.039, la),
		]
		tube("cloth", cloth, sleeve, 6)
		# bare forearm and hand (bracer on rangers)
		var fore := [
			_ring(Vector3(sg * absf(wrist_x), yy, lerpf(p_la.z, p_hd.z, wrist_t)), Y, Z, 0.033, 0.033, la),
			_ring(Vector3(p_hd.x, yy, p_hd.z), Y, Z, 0.03, 0.03, la, hd, 0.5),
		]
		tube("skin", skinm, fore, 5)
		box("skin", skinm, Vector3(sg * (absf(p_hd.x) + 0.05), yy - 0.005, p_hd.z + 0.01), Vector3(0.1, 0.035, 0.085), hd)
		if ranger:
			tube("trim", trim, [_ring(Vector3(sg * (absf(p_la.x) + 0.09), yy, p_la.z), Y, Z, 0.043, 0.043, la), _ring(Vector3(sg * (absf(p_la.x) + 0.16), yy, p_la.z), Y, Z, 0.04, 0.04, la)], 6)
		# trousers: thigh to ankle, six-sided; boots on the feet
		var th := _bone("thigh_" + side)
		var ca := _bone("calf_" + side)
		var ft := _bone("foot_" + side)
		var p_th := _rest("thigh_" + side)
		var p_ca := _rest("calf_" + side)
		var p_ft := _rest("foot_" + side)
		var leg := [
			_ring(Vector3(p_th.x, 0.97, p_th.z), X, Z, 0.092, 0.09, th),
			_ring(Vector3(p_th.x, 0.76, p_th.z), X, Z, 0.08, 0.078, th),
			_ring(Vector3(p_ca.x, p_ca.y, p_ca.z), X, Z, 0.062, 0.062, th, ca, 0.5),
			_ring(Vector3(p_ft.x, 0.2, p_ft.z + 0.01), X, Z, 0.05, 0.05, ca),
		]
		tube("pants", pants, leg, 6)
		var boot_top := [
			_ring(Vector3(p_ft.x, 0.22, p_ft.z + 0.01), X, Z, 0.056, 0.058, ca),
			_ring(Vector3(p_ft.x, 0.1, p_ft.z + 0.01), X, Z, 0.058, 0.06, ca, ft, 0.5),
		]
		tube("boots", boots, boot_top, 6)
		box("boots", boots, Vector3(p_ft.x, 0.045, p_ft.z + 0.075), Vector3(0.105, 0.09, 0.25), ft)

func _commit() -> Array:
	var mesh := ArrayMesh.new()
	var order := ["cloth", "trim", "pants", "skin", "boots"]
	for n in surfaces.keys():
		if n not in order:
			order.append(n)
	var surf_names := []
	for n in order:
		if not surfaces.has(n):
			continue
		var st: SurfaceTool = surfaces[n]
		st.generate_normals()
		st.commit(mesh)
		surf_names.append(n)
	for i in surf_names.size():
		mesh.surface_set_material(i, mats[surf_names[i]])
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = mesh_name
	skel.add_child(mi)
	mi.skin = skel.create_skin_from_rest_transforms()
	mi.skeleton = NodePath("..")
	return [mi]

## Small faceted shoulder plates on the upper arm, for armoured kits.
static func pauldrons(skel_: Skeleton3D, kit: String, sex: String, palette: Dictionary) -> Array:
	var o = load("res://scripts/actors/lowpoly_outfit.gd").new()
	o.skel = skel_
	o.mesh_name = "LowpolyPauldrons"
	var col := Color(0.18, 0.08, 0.08) if kit.begins_with("fn_") else Color(palette.primary).darkened(0.2)
	var mat: Material = Accessories.mat(col)
	var X := Vector3.RIGHT
	var Z := Vector3.BACK
	for side in ["l", "r"]:
		var sg := 1.0 if side == "l" else -1.0
		var ua: int = o._bone("upperarm_" + side)
		var p: Vector3 = o._rest("upperarm_" + side)
		var wid := 0.082 * (0.92 if sex == "f" else 1.0)
		# a flattened dome over the shoulder joint: three rings and a cap
		var rings := [
			o._ring(Vector3(sg * (absf(p.x) + 0.075), p.y - 0.045, p.z), Vector3.UP, Z, wid * 0.95, wid * 1.05, ua),
			o._ring(Vector3(sg * (absf(p.x) + 0.04), p.y - 0.01, p.z), Vector3.UP, Z, wid, wid * 1.1, ua),
			o._ring(Vector3(sg * (absf(p.x) + 0.0), p.y + 0.03, p.z), Vector3.UP, Z, wid * 0.8, wid * 0.95, ua),
			o._ring(Vector3(sg * (absf(p.x) - 0.04), p.y + 0.055, p.z), Vector3.UP, Z, wid * 0.4, wid * 0.5, ua),
		]
		o.tube("plate", mat, rings, 6, true)
	return o._commit()

## Hand-built hair: a solid cap with a few faceted pieces (tails, buns, a
## beard), 40-120 triangles, in one flat colour. `head` is the head mesh's
## bounds in rig space.
static func hair(skel_: Skeleton3D, style: String, colour: Color, head: AABB) -> Array:
	var o = load("res://scripts/actors/lowpoly_outfit.gd").new()
	o.skel = skel_
	o.mesh_name = "LowpolyHair"
	var mat: Material = Accessories.mat(colour)
	var X := Vector3.RIGHT
	var Z := Vector3.BACK
	var Y := Vector3.UP
	var hb: int = o._bone("Head")
	var top: float = head.end.y
	var cz: float = head.get_center().z - 0.004
	var rx: float = minf(head.size.x * 0.5, 0.1) + 0.006
	var rz: float = minf(head.size.z * 0.5, 0.12) + 0.004
	var thick := 1.0 if style != "Hair_Beard" else 0.0
	var cap_base := top - 0.085
	if style == "Hair_Beard":
		var chin := top - 0.245
		o.tube("hair", mat, [
			o._ring(Vector3(0, top - 0.15, cz + rz * 0.38), X, Z, rx * 0.72, rz * 0.5, hb),
			o._ring(Vector3(0, top - 0.2, cz + rz * 0.52), X, Z, rx * 0.6, rz * 0.46, hb),
			o._ring(Vector3(0, chin, cz + rz * 0.5), X, Z, rx * 0.28, rz * 0.3, hb),
		], 6, true)
		return o._commit()
	var cap := [
		o._ring(Vector3(0, cap_base, cz - 0.004), X, Z, rx * 1.0, rz * 1.0, hb),
		o._ring(Vector3(0, top - 0.055, cz - 0.004), X, Z, rx * 1.02, rz * 1.02, hb),
		o._ring(Vector3(0, top - 0.025, cz - 0.004), X, Z, rx * 0.9, rz * 0.92, hb),
		o._ring(Vector3(0, top - 0.004, cz - 0.004), X, Z, rx * 0.6, rz * 0.62, hb),
		o._ring(Vector3(0, top + 0.012, cz - 0.004), X, Z, rx * 0.25, rz * 0.27, hb),
	]
	o.tube("hair", mat, cap, 8, true)
	match style:
		"Hair_SimpleParted":
			# side locks and a nape piece
			for sg in [-1.0, 1.0]:
				o.box("hair", mat, Vector3(sg * (rx - 0.004), top - 0.115, cz), Vector3(0.026, 0.07, rz * 1.5), hb)
			o.box("hair", mat, Vector3(0, top - 0.115, cz - rz + 0.012), Vector3(rx * 1.7, 0.075, 0.03), hb)
		"Hair_Long":
			var back := cz - rz * 0.7
			o.tube("hair", mat, [
				o._ring(Vector3(0, top - 0.07, back), X, Z, rx * 0.95, 0.04, hb),
				o._ring(Vector3(0, top - 0.17, back - 0.01), X, Z, rx * 1.0, 0.04, hb),
				o._ring(Vector3(0, top - 0.3, back - 0.02), X, Z, rx * 0.9, 0.035, hb, o._bone("neck_01"), 0.5),
				o._ring(Vector3(0, top - 0.43, back - 0.03), X, Z, rx * 0.7, 0.03, o._bone("neck_01"), o._bone("spine_03"), 0.6),
			], 6)
		"Hair_Buns":
			for sg in [-1.0, 1.0]:
				var bx: float = sg * rx * 0.7
				o.tube("hair", mat, [
					o._ring(Vector3(bx, top - 0.01, cz - 0.01), X, Z, 0.034, 0.034, hb),
					o._ring(Vector3(bx, top + 0.022, cz - 0.01), X, Z, 0.046, 0.046, hb),
					o._ring(Vector3(bx, top + 0.05, cz - 0.01), X, Z, 0.036, 0.036, hb),
					o._ring(Vector3(bx, top + 0.068, cz - 0.01), X, Z, 0.012, 0.012, hb),
				], 6, true)
			o.box("hair", mat, Vector3(0, top - 0.105, cz - rz + 0.012), Vector3(rx * 1.7, 0.07, 0.03), hb)
	return o._commit()
