extends RefCounted
## Facial expressions for the CC0 base heads, which ship without morph targets.
## At load time we locate facial landmarks (eyes from the eye mesh, mouth and
## chin from the head geometry) and generate blend shapes by displacing the
## surrounding vertices with smooth falloffs:
##   head:  smile_l, smile_r, frown, jaw_open, blink_l, blink_r, cheek_raise
##   brows: brow_up, brow_angry, brow_sad
## Expressions are named presets that mix these shapes (see EXPRESSIONS).

const EXPRESSIONS := {
	"neutral": {},
	"happy": {"smile_l": 0.8, "smile_r": 0.8, "cheek_raise": 0.5, "brow_up": 0.2},
	"laugh": {"smile_l": 1.0, "smile_r": 1.0, "jaw_open": 0.55, "cheek_raise": 0.9, "blink_l": 0.35, "blink_r": 0.35},
	"smirk": {"smile_l": 0.85, "brow_up": 0.15},
	"sad": {"frown": 0.75, "brow_sad": 1.0, "blink_l": 0.25, "blink_r": 0.25},
	"grief": {"frown": 1.0, "brow_sad": 1.0, "jaw_open": 0.2, "blink_l": 0.45, "blink_r": 0.45},
	"angry": {"frown": 0.55, "brow_angry": 1.0, "blink_l": 0.2, "blink_r": 0.2},
	"furious": {"frown": 0.4, "brow_angry": 1.0, "jaw_open": 0.35, "blink_l": 0.15, "blink_r": 0.15},
	"surprised": {"brow_up": 1.0, "jaw_open": 0.55},
	"afraid": {"brow_sad": 0.7, "brow_up": 0.6, "jaw_open": 0.3, "frown": 0.3},
	"determined": {"brow_angry": 0.45, "frown": 0.15, "blink_l": 0.12, "blink_r": 0.12},
	"thoughtful": {"brow_angry": 0.2, "smile_r": 0.2, "blink_l": 0.2, "blink_r": 0.2},
	"tender": {"smile_l": 0.45, "smile_r": 0.45, "brow_sad": 0.35, "blink_l": 0.2, "blink_r": 0.2},
	"embarrassed": {"smile_l": 0.35, "smile_r": 0.2, "brow_sad": 0.5, "blink_l": 0.3, "blink_r": 0.3},
	"pain": {"frown": 0.6, "brow_angry": 0.5, "brow_sad": 0.5, "jaw_open": 0.3, "blink_l": 0.6, "blink_r": 0.6},
	"sleep": {"blink_l": 1.0, "blink_r": 1.0},
}

static var _cache := {}

static func _smooth(d: float, r: float) -> float:
	if d >= r:
		return 0.0
	var t := 1.0 - d / r
	return t * t * (3.0 - 2.0 * t)

## Adds blend shapes to the head and brow meshes (cached per base mesh).
static func setup(parts: Dictionary) -> void:
	var head: MeshInstance3D = parts.get("head")
	var eyes: MeshInstance3D = parts.get("eyes")
	var brows: MeshInstance3D = parts.get("brows")
	if head == null or eyes == null:
		return
	var key := String(head.mesh.resource_name) + str(head.mesh.get_instance_id())
	if not _cache.has(key):
		_cache[key] = _build(head.mesh, eyes.mesh, brows.mesh if brows else null)
	var c: Dictionary = _cache[key]
	var head_mat := head.get_surface_override_material(0)
	head.mesh = c.head
	head.set_surface_override_material(0, head_mat)
	if brows and c.brows:
		var brow_mat := brows.get_surface_override_material(0)
		brows.mesh = c.brows
		brows.set_surface_override_material(0, brow_mat)
	parts.face = c.landmarks

static func _eye_centres(eyes: Mesh) -> Array:
	var v: PackedVector3Array = eyes.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var l := Vector3.ZERO
	var r := Vector3.ZERO
	var nl := 0
	var nr := 0
	var front := -INF
	for p in v:
		front = maxf(front, p.z)
		if p.x > 0.0:
			l += p
			nl += 1
		else:
			r += p
			nr += 1
	l /= maxi(1, nl)
	r /= maxi(1, nr)
	return [l, r, front]

static func _build(head_mesh: ArrayMesh, eyes_mesh: Mesh, brow_mesh: Mesh) -> Dictionary:
	var ec := _eye_centres(eyes_mesh)
	var eye_l: Vector3 = ec[0]
	var eye_r: Vector3 = ec[1]
	var eye_front: float = ec[2]
	var eye_y := (eye_l.y + eye_r.y) / 2.0
	var eye_dx := absf(eye_l.x - eye_r.x) / 2.0
	var arrays := head_mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	# Chin: lowest point on the front midline below the eyes
	var chin_y := eye_y
	var front_z := -INF
	for p in verts:
		if absf(p.x) < 0.012 and p.y < eye_y and p.y > eye_y - 0.17 and p.z > eye_front - 0.035:
			if p.z > front_z - 0.03:
				chin_y = minf(chin_y, p.y)
			front_z = maxf(front_z, p.z)
	var face_h := eye_y - chin_y
	var mouth_y := eye_y - face_h * 0.64
	var mouth_dx := eye_dx * 0.72
	var lm := {"eye_l": eye_l, "eye_r": eye_r, "mouth_y": mouth_y, "chin_y": chin_y}
	var shapes := {
		"smile_l": PackedVector3Array(), "smile_r": PackedVector3Array(), "frown": PackedVector3Array(),
		"jaw_open": PackedVector3Array(), "blink_l": PackedVector3Array(), "blink_r": PackedVector3Array(),
		"cheek_raise": PackedVector3Array(),
	}
	for k in shapes:
		shapes[k] = verts.duplicate()
	var front_min := eye_front - 0.06
	for i in verts.size():
		var p := verts[i]
		if p.z < front_min:
			continue
		var front_w := clampf((p.z - front_min) / 0.04, 0.0, 1.0)
		for side in [1, -1]:
			var corner := Vector3(mouth_dx * side, mouth_y, 0)
			var d := Vector2(p.x - corner.x, (p.y - corner.y) * 1.3).length()
			var w := _smooth(d, 0.03) * front_w
			if w > 0.0:
				var key := "smile_l" if side == 1 else "smile_r"
				shapes[key][i] = p + Vector3(0.006 * side, 0.012, -0.004) * w
				shapes.frown[i] = shapes.frown[i] + Vector3(0.0, -0.01, 0.001) * w
			# cheeks
			var cheek := Vector3(eye_dx * 1.05 * side, eye_y - face_h * 0.32, 0)
			var dc := Vector2(p.x - cheek.x, p.y - cheek.y).length()
			var wc := _smooth(dc, 0.03) * front_w
			if wc > 0.0:
				shapes.cheek_raise[i] = shapes.cheek_raise[i] + Vector3(0, 0.005, 0.002) * wc
			# eyelids: skin just above the eye slides down over the eyeball
			var ec2: Vector3 = eye_l if side == 1 else eye_r
			var de := Vector2(p.x - ec2.x, (p.y - ec2.y)).length()
			if p.y > ec2.y - 0.002 and de < 0.024:
				var wl := _smooth(de, 0.024)
				var target_y := ec2.y - 0.004
				var key2 := "blink_l" if side == 1 else "blink_r"
				var np := p
				np.y = lerpf(p.y, target_y + (p.y - ec2.y) * 0.15, wl)
				np.z = p.z + 0.004 * wl
				shapes[key2][i] = np
		# jaw: lower face below the mouth line drops and tilts back
		if p.y < mouth_y + 0.004 and p.y > chin_y - 0.03 and absf(p.x) < 0.075:
			var wj := clampf((mouth_y + 0.004 - p.y) / 0.02, 0.0, 1.0) * front_w * _smooth(absf(p.x), 0.075)
			shapes.jaw_open[i] = p + Vector3(0, -0.024, -0.006) * wj
	var out := ArrayMesh.new()
	out.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	var bs_arrays := []
	for k in shapes:
		out.add_blend_shape(k)
		var a := []
		a.resize(Mesh.ARRAY_MAX)
		a[Mesh.ARRAY_VERTEX] = shapes[k]
		a[Mesh.ARRAY_NORMAL] = norms
		if arrays[Mesh.ARRAY_TANGENT] != null:
			a[Mesh.ARRAY_TANGENT] = arrays[Mesh.ARRAY_TANGENT]
		bs_arrays.append(a)
	var stride: int = arrays[Mesh.ARRAY_BONES].size() / verts.size()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, bs_arrays, {}, Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if stride == 8 else 0)
	out.surface_set_material(0, head_mesh.surface_get_material(0))
	var brow_out: ArrayMesh = null
	if brow_mesh:
		brow_out = _brow_shapes(brow_mesh, eye_l, eye_r)
	return {"head": out, "brows": brow_out, "landmarks": lm}

static func _brow_shapes(brow_mesh: Mesh, eye_l: Vector3, eye_r: Vector3) -> ArrayMesh:
	var arrays := brow_mesh.surface_get_arrays(0)
	for c in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3]:
		arrays[c] = null
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var up := verts.duplicate()
	var angry := verts.duplicate()
	var sad := verts.duplicate()
	var half := maxf(0.001, absf(eye_l.x - eye_r.x) / 2.0)
	for i in verts.size():
		var p := verts[i]
		# 0 at the inner end of each brow, 1 at the outer end
		var t := clampf((absf(p.x) - half * 0.25) / (half * 1.5), 0.0, 1.0)
		up[i] = p + Vector3(0, 0.011, 0.002)
		angry[i] = p + Vector3(-signf(p.x) * 0.004 * (1.0 - t), -0.011 * (1.0 - t) + 0.003 * t, 0.002)
		sad[i] = p + Vector3(0, 0.011 * (1.0 - t) - 0.003 * t, 0.001)
	var out := ArrayMesh.new()
	out.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	var bs := []
	for pair in [["brow_up", up], ["brow_angry", angry], ["brow_sad", sad]]:
		out.add_blend_shape(pair[0])
		var a := []
		a.resize(Mesh.ARRAY_MAX)
		a[Mesh.ARRAY_VERTEX] = pair[1]
		a[Mesh.ARRAY_NORMAL] = arrays[Mesh.ARRAY_NORMAL]
		if arrays[Mesh.ARRAY_TANGENT] != null:
			a[Mesh.ARRAY_TANGENT] = arrays[Mesh.ARRAY_TANGENT]
		bs.append(a)
	var stride := 4
	if arrays[Mesh.ARRAY_BONES] != null:
		stride = arrays[Mesh.ARRAY_BONES].size() / verts.size()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, bs, {}, Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if stride == 8 else 0)
	out.surface_set_material(0, brow_mesh.surface_get_material(0))
	return out

## Apply an expression preset immediately (weight 0..1 scales it).
static func set_expression(parts: Dictionary, expr: String, weight: float = 1.0) -> void:
	var target: Dictionary = EXPRESSIONS.get(expr, {})
	for mi in [parts.get("head"), parts.get("brows")]:
		if mi == null:
			continue
		var m: Mesh = mi.mesh
		for i in m.get_blend_shape_count():
			var n := String(m.get_blend_shape_name(i))
			mi.set_blend_shape_value(i, float(target.get(n, 0.0)) * weight)
