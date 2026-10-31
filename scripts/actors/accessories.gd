extends RefCounted
## Culture-specific garments and headwear layered over the base outfits:
## Fire Nation helmets, shoulder guards and plate tassets, Earth Kingdom conical
## helmets and tabards, Air Nomad robes and sashes, Water Tribe fur collars and
## wolf helms, Tide Warden headbands, sandbender wraps and so on.
##
## Each piece is modelled in the rig's T-pose model space (character faces +Z,
## ~1.8 m tall) and bound to a skeleton bone, so it follows the animation.

const MODEL := preload("res://shaders/model.gdshader")
const MODEL_DOUBLE := preload("res://shaders/model_double.gdshader")

static var _mats := {}

static func mat(c: Color, outline: bool = true, rim: float = 0.25, double: bool = false) -> ShaderMaterial:
	var key := "%s_%s_%s_%s" % [c.to_html(), outline, rim, double]
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = MODEL_DOUBLE if double else MODEL
	var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	var t := ImageTexture.create_from_image(img)
	m.set_shader_parameter("albedo_tex", t)
	m.set_shader_parameter("albedo_tex_b", t)
	m.set_shader_parameter("tint", c)
	# muted and worn rather than flat, bright paint
	m.set_shader_parameter("saturation", 0.72)
	m.set_shader_parameter("grain", 1.0)
	_mats[key] = m
	return m

# ---------------------------------------------------------------------------
# Mesh helpers (smooth, lathed and curved shapes)
# ---------------------------------------------------------------------------
## Revolve a 2D profile [(radius, height), ...] around Y.
static func lathe(profile: Array, segs: int = 24, sx: float = 1.0, sz: float = 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for i in profile.size() - 1:
		var a: Vector2 = profile[i]
		var b: Vector2 = profile[i + 1]
		for s in segs:
			var t0 := TAU * s / segs
			var t1 := TAU * (s + 1) / segs
			var p00 := Vector3(cos(t0) * a.x * sx, a.y, sin(t0) * a.x * sz)
			var p01 := Vector3(cos(t1) * a.x * sx, a.y, sin(t1) * a.x * sz)
			var p10 := Vector3(cos(t0) * b.x * sx, b.y, sin(t0) * b.x * sz)
			var p11 := Vector3(cos(t1) * b.x * sx, b.y, sin(t1) * b.x * sz)
			for p in [p00, p10, p01, p01, p10, p11]:
				st.add_vertex(p)
	st.generate_normals()
	return st.commit()

## A curved plate: part of a cylinder wall (angle span in degrees), with thickness.
static func shell(radius: float, height: float, span_deg: float, _thick: float = 0.012, segs: int = 12, flare: float = 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := deg_to_rad(span_deg) / 2.0
	var rows := 4
	for r in rows:
		var y0 := -height * r / rows
		var y1 := -height * (r + 1) / rows
		var r0 := radius + flare * float(r) / rows
		var r1 := radius + flare * float(r + 1) / rows
		for s in segs:
			var a0 := -half + 2.0 * half * s / segs
			var a1 := -half + 2.0 * half * (s + 1) / segs
			var p0 := Vector3(sin(a0) * r0, y0, cos(a0) * r0)
			var p1 := Vector3(sin(a1) * r0, y0, cos(a1) * r0)
			var p2 := Vector3(sin(a0) * r1, y1, cos(a0) * r1)
			var p3 := Vector3(sin(a1) * r1, y1, cos(a1) * r1)
			for p in [p0, p2, p1, p1, p2, p3]:
				st.set_normal(Vector3(p.x, 0, p.z).normalized())
				st.add_vertex(p)
	return st.commit()

## Thin panels (cloth, plates) are double-sided and drawn without the hull outline.
static func panel(mesh: Mesh, c: Color, xf: Transform3D = Transform3D.IDENTITY) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(c, false, 0.25, true)
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

static func node(mesh: Mesh, c: Color, xf: Transform3D = Transform3D.IDENTITY, outline: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(c, outline)
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

static func box(size: Vector3, c: Color, xf: Transform3D = Transform3D.IDENTITY) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return node(b, c, xf)

static func sphere(r: float, c: Color, xf: Transform3D = Transform3D.IDENTITY, hemi: bool = false) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * (1.0 if hemi else 2.0)
	s.is_hemisphere = hemi
	s.radial_segments = 20
	s.rings = 10
	return node(s, c, xf)

static func torus(inner: float, outer: float, c: Color, xf: Transform3D = Transform3D.IDENTITY) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 24
	t.ring_segments = 10
	return node(t, c, xf)

static func at(pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> Transform3D:
	var b := Basis.from_euler(rot_deg * PI / 180.0).scaled(scale)
	return Transform3D(b, pos)

# ---------------------------------------------------------------------------
# Binding to the skeleton
# ---------------------------------------------------------------------------
## Attach a piece authored in T-pose model space to a bone.
static func bind(parts: Dictionary, bone: String, piece: Node3D) -> void:
	var skel: Skeleton3D = parts.skeleton
	var idx := skel.find_bone(bone)
	if idx < 0:
		return
	var key := "att_" + bone
	var att: BoneAttachment3D = parts.get(key)
	if att == null:
		att = BoneAttachment3D.new()
		att.bone_name = bone
		skel.add_child(att)
		parts[key] = att
	var rest := skel.get_bone_global_rest(idx)
	piece.transform = rest.affine_inverse() * piece.transform
	att.add_child(piece)

# ---------------------------------------------------------------------------
# Head pieces. Head centre is about (0, 1.68, 0.02) for men, (0, 1.63, 0.02) for women.
# ---------------------------------------------------------------------------
static func head_y(sex: String) -> float:
	return 1.68 if sex == "m" else 1.635

static func dress_head(parts: Dictionary, style: String, sex: String, hair: Color, palette: Dictionary) -> void:
	var y := head_y(sex)
	var top := y + 0.115
	var red := Color(0.62, 0.1, 0.08)
	var gold := Color(0.92, 0.72, 0.25)
	var add := func(piece: Node3D): bind(parts, "Head", piece)
	match style:
		"fn_helmet":
			add.call(node(lathe([Vector2(0.0, 0.135), Vector2(0.05, 0.13), Vector2(0.1, 0.1), Vector2(0.125, 0.05), Vector2(0.13, 0.0), Vector2(0.135, -0.04)], 24, 1.0, 1.08), Color(0.32, 0.12, 0.1), at(Vector3(0, top - 0.06, -0.005))))
			# white face guard
			add.call(panel(shell(0.122, 0.11, 110.0, 0.01, 12, 0.012), Color(0.9, 0.88, 0.82), at(Vector3(0, y + 0.02, -0.005))))
			# flame crest
			add.call(node(lathe([Vector2(0.0, 0.07), Vector2(0.018, 0.02), Vector2(0.025, 0.0)], 10, 0.6, 1.4), Color(0.2, 0.06, 0.05), at(Vector3(0, top + 0.06, 0.0))))
		"fn_officer":
			dress_head(parts, "fn_helmet", sex, hair, palette)
			add.call(node(lathe([Vector2(0.0, 0.11), Vector2(0.03, 0.05), Vector2(0.035, 0.0)], 12, 0.4, 1.6), gold, at(Vector3(0, top + 0.08, 0.0))))
		"fn_cap":
			add.call(node(lathe([Vector2(0.0, 0.06), Vector2(0.08, 0.05), Vector2(0.125, 0.02), Vector2(0.128, 0.0)], 20), red, at(Vector3(0, top - 0.04, 0.0))))
		"topknot":
			add.call(sphere(0.04, hair * 1.4, at(Vector3(0, top + 0.01, -0.03))))
		"fn_noble":
			add.call(sphere(0.04, hair * 1.4, at(Vector3(0, top + 0.01, -0.03))))
			add.call(node(lathe([Vector2(0.0, 0.07), Vector2(0.012, 0.04), Vector2(0.026, 0.0)], 8, 0.5, 1.5), gold, at(Vector3(0, top + 0.035, -0.03))))
		"ek_hat":
			add.call(node(lathe([Vector2(0.0, 0.14), Vector2(0.06, 0.09), Vector2(0.17, 0.02), Vector2(0.2, -0.005), Vector2(0.19, -0.02), Vector2(0.11, 0.0)], 28), Color(0.28, 0.42, 0.22), at(Vector3(0, top - 0.035, 0.0))))
			add.call(node(lathe([Vector2(0.0, 0.03), Vector2(0.012, 0.0)], 8), gold, at(Vector3(0, top + 0.1, 0.0))))
		"straw_hat":
			add.call(node(lathe([Vector2(0.0, 0.12), Vector2(0.12, 0.05), Vector2(0.27, -0.01), Vector2(0.27, -0.025), Vector2(0.1, 0.02)], 28), Color(0.86, 0.74, 0.45), at(Vector3(0, top - 0.03, 0.0))))
		"ek_helm":
			add.call(node(lathe([Vector2(0.0, 0.15), Vector2(0.06, 0.13), Vector2(0.12, 0.06), Vector2(0.135, 0.0), Vector2(0.15, -0.03), Vector2(0.155, -0.045), Vector2(0.13, -0.04)], 24), Color(0.22, 0.36, 0.2), at(Vector3(0, top - 0.06, 0.0))))
			add.call(node(lathe([Vector2(0.0, 0.05), Vector2(0.01, 0.0)], 8), Color(0.85, 0.7, 0.3), at(Vector3(0, top + 0.09, 0.0))))
			add.call(torus(0.13, 0.145, gold, at(Vector3(0, top - 0.06, 0.0))))
		"censor":
			# a censor's flat-topped black gauze cap with a jade bead
			add.call(node(lathe([Vector2(0.0, 0.1), Vector2(0.12, 0.1), Vector2(0.125, 0.0)], 4), Color(0.08, 0.08, 0.09), at(Vector3(0, top - 0.05, 0.0), Vector3(0, 45, 0))))
			add.call(node(lathe([Vector2(0.0, 0.02), Vector2(0.02, 0.0)], 8), Color(0.35, 0.6, 0.45), at(Vector3(0, top + 0.03, 0.12))))
		"hamakaze":
			# the Tide Wardens' white headband, knotted at the back
			add.call(torus(0.112, 0.128, Color(0.94, 0.93, 0.9), at(Vector3(0, y + 0.06, 0.0), Vector3(-6, 0, 0))))
		"parka", "wt_helm":
			# the hood itself comes from the outfit kit; add the fur trim
			add.call(torus(0.1, 0.135, Color(0.95, 0.94, 0.9), at(Vector3(0, y + 0.0, 0.065), Vector3(80, 0, 0), Vector3(1.0, 1.0, 1.2))))
		"wolf":
			var grey := Color(0.6, 0.6, 0.64)
			add.call(node(lathe([Vector2(0.0, 0.12), Vector2(0.09, 0.1), Vector2(0.13, 0.04), Vector2(0.135, -0.02)], 20, 1.0, 1.15), grey, at(Vector3(0, top - 0.05, -0.01))))
			for sx in [-1, 1]:
				add.call(node(lathe([Vector2(0.0, 0.08), Vector2(0.03, 0.0)], 8, 1.0, 0.5), grey, at(Vector3(0.07 * sx, top + 0.04, -0.02), Vector3(0, 0, -15 * sx))))
			add.call(node(lathe([Vector2(0.0, 0.0), Vector2(0.05, 0.03), Vector2(0.06, 0.09)], 10, 1.0, 0.7), grey, at(Vector3(0, top - 0.02, 0.12), Vector3(90, 0, 0))))
		"warpaint":
			add.call(sphere(0.045, hair * 1.4, at(Vector3(0, top - 0.02, -0.11))))
		"bandana":
			add.call(sphere(0.128, Color(0.55, 0.1, 0.12), at(Vector3(0, y + 0.03, -0.01), Vector3(-10, 0, 0), Vector3(1, 0.85, 1.05)), true))
		"pirate_hat":
			# low-crowned captain's hat with a rolled brim, dyed oxblood
			add.call(node(lathe([Vector2(0.0, 0.1), Vector2(0.105, 0.095), Vector2(0.118, 0.025), Vector2(0.165, 0.02), Vector2(0.178, 0.045), Vector2(0.17, 0.0), Vector2(0.115, -0.008)], 24, 1.0, 0.8), Color(0.28, 0.09, 0.07), at(Vector3(0, top - 0.045, 0.0))))
		"sand_wrap":
			# hood from the outfit kit plus an indigo veil over the mouth
			add.call(panel(shell(0.118, 0.08, 150.0, 0.01, 14, 0.02), Color(0.3, 0.28, 0.52), at(Vector3(0, y - 0.03, 0.0))))
		"yuyan":
			add.call(sphere(0.13, Color(0.1, 0.06, 0.06), at(Vector3(0, y + 0.04, -0.012), Vector3.ZERO, Vector3(1, 0.85, 1.05)), true))
			add.call(panel(shell(0.124, 0.03, 120.0, 0.006, 12), Color(0.6, 0.1, 0.1), at(Vector3(0, y + 0.03, 0.0))))
		"air_arrow":
			# blue arrow tattoo from the brow over the crown to the nape
			var c := Vector3(0, y + 0.008, 0.005)
			var r := 0.122
			var arrow_c := Color(0.2, 0.5, 0.95)
			for i in 32:
				var phi := deg_to_rad(lerpf(58.0, -95.0, i / 31.0))
				var p := c + Vector3(0, cos(phi) * r, sin(phi) * r)
				add.call(node(SphereMesh.new(), arrow_c, at(p, Vector3(rad_to_deg(phi), 0, 0), Vector3(0.028, 0.006, 0.03)), false))
			var tip_phi := deg_to_rad(66.0)
			add.call(node(lathe([Vector2(0.0, 0.035), Vector2(0.03, 0.0)], 3, 1.0, 0.25), arrow_c, at(c + Vector3(0, cos(tip_phi) * (r + 0.002), sin(tip_phi) * (r + 0.002)), Vector3(180 - rad_to_deg(tip_phi) + 90, 0, 0)), false))

# ---------------------------------------------------------------------------
# Body garments
# ---------------------------------------------------------------------------
## True while the hand-built low-poly outfits are in use: belts and shoulder
## guards then come from lowpoly_outfit.gd, skinned to the rig.
static func _lp() -> bool:
	return GS.settings.get("lowpoly_outfits", true)

static func dress_body(parts: Dictionary, kit: String, sex: String, palette: Dictionary) -> void:
	if _lp() and kit in ["fn_armor", "fn_heavy", "ek_armor"]:
		parts.meshes.append_array(load("res://scripts/actors/lowpoly_outfit.gd").pauldrons(parts.skeleton, kit, sex, palette))
	var w := 1.0 if sex == "m" else 0.9
	var hip_y := 0.97 if sex == "m" else 0.95
	var primary: Color = palette.get("primary", Color(0.5, 0.5, 0.5))
	var secondary: Color = palette.get("secondary", Color(0.3, 0.3, 0.3))
	var accent: Color = palette.get("accent", Color(0.9, 0.7, 0.25))
	match kit:
		"fn_armor", "fn_heavy":
			# shoulder guards
			for side in ([] if _lp() else ["l", "r"]):
				var sx := 1.0 if side == "l" else -1.0
				var sh := panel(shell(0.075, 0.13, 200.0, 0.012, 12, 0.03), Color(0.18, 0.08, 0.08), at(Vector3(0.22 * sx * w, 1.5 if sex == "m" else 1.46, -0.06), Vector3(0, 0, -78 * sx)))
				bind(parts, "upperarm_" + side, sh)
			# chest plate and tassets
			bind(parts, "spine_03", panel(shell(0.15 * w, 0.22, 120.0, 0.014, 14, 0.01), Color(0.22, 0.1, 0.09), at(Vector3(0, 1.43 if sex == "m" else 1.39, -0.02))))
			for side in ["l", "r"]:
				var sx2 := 1.0 if side == "l" else -1.0
				bind(parts, "thigh_" + side, panel(shell(0.11, 0.24, 120.0, 0.012, 10, 0.05), Color(0.2, 0.09, 0.08), at(Vector3(0.1 * sx2, hip_y + 0.02, 0.0))))
				bind(parts, "thigh_" + side, panel(shell(0.11, 0.22, 100.0, 0.012, 10, 0.05), Color(0.2, 0.09, 0.08), at(Vector3(0.1 * sx2, hip_y + 0.02, 0.0), Vector3(0, 180, 0))))
			if not _lp(): bind(parts, "pelvis", torus(0.15 * w, 0.175 * w, accent, at(Vector3(0, hip_y + 0.04, -0.03), Vector3.ZERO, Vector3(1, 1, 0.8))))
		"ek_armor":
			# tabard front and back, gold-trimmed belt, round shoulder plates
			bind(parts, "spine_03", panel(shell(0.17 * w, 0.42, 70.0, 0.01, 10, 0.03), primary, at(Vector3(0, 1.44 if sex == "m" else 1.4, -0.03))))
			bind(parts, "spine_03", panel(shell(0.17 * w, 0.42, 70.0, 0.01, 10, 0.03), primary, at(Vector3(0, 1.44 if sex == "m" else 1.4, -0.03), Vector3(0, 180, 0))))
			if not _lp(): bind(parts, "pelvis", torus(0.15 * w, 0.18 * w, Color(0.35, 0.25, 0.15), at(Vector3(0, hip_y + 0.05, -0.03), Vector3.ZERO, Vector3(1, 1, 0.8))))
			for side in ([] if _lp() else ["l", "r"]):
				var sx3 := 1.0 if side == "l" else -1.0
				bind(parts, "upperarm_" + side, node(lathe([Vector2(0.0, 0.03), Vector2(0.07, 0.01), Vector2(0.08, -0.03)], 16), primary.darkened(0.15), at(Vector3(0.21 * sx3 * w, 1.5 if sex == "m" else 1.46, -0.06), Vector3(0, 0, -80 * sx3))))
		"air_robes":
			# saffron robe skirt, yellow sash, mantle over one shoulder
			for side in ["l", "r"]:
				var sx4 := 1.0 if side == "l" else -1.0
				bind(parts, "thigh_" + side, panel(shell(0.14, 0.55, 160.0, 0.01, 12, 0.07), Color(0.95, 0.55, 0.12), at(Vector3(0.08 * sx4, hip_y + 0.03, 0.0))))
				bind(parts, "thigh_" + side, panel(shell(0.14, 0.55, 160.0, 0.01, 12, 0.07), Color(0.95, 0.55, 0.12), at(Vector3(0.08 * sx4, hip_y + 0.03, 0.0), Vector3(0, 180, 0))))
			if not _lp(): bind(parts, "pelvis", torus(0.15 * w, 0.185 * w, Color(0.98, 0.82, 0.3), at(Vector3(0, hip_y + 0.05, -0.03), Vector3.ZERO, Vector3(1, 1.2, 0.8))))
			# yellow mantle worn as a diagonal sash across the chest
			bind(parts, "spine_03", torus(0.15 * w, 0.2 * w, Color(0.98, 0.8, 0.28), at(Vector3(0.0, 1.36 if sex == "m" else 1.32, -0.02), Vector3(0, 0, 32), Vector3(1.0, 1.0, 0.72))))
		"water_fur":
			var fur := Color(0.95, 0.94, 0.9)
			bind(parts, "spine_03", torus(0.12 * w, 0.17 * w, fur, at(Vector3(0, 1.5 if sex == "m" else 1.46, -0.03), Vector3.ZERO, Vector3(1.1, 1.3, 0.9))))
			if not _lp(): bind(parts, "pelvis", torus(0.15 * w, 0.18 * w, primary.darkened(0.2), at(Vector3(0, hip_y + 0.05, -0.03), Vector3.ZERO, Vector3(1, 1, 0.8))))
			for side in ["l", "r"]:
				bind(parts, "lowerarm_" + side, torus(0.04, 0.065, fur, at(Vector3((0.66 if sex == "m" else 0.6) * (1.0 if side == "l" else -1.0), 1.45 if sex == "m" else 1.415, -0.06), Vector3(0, 0, 90))))
		"tide_armor":
			bind(parts, "spine_03", panel(shell(0.16 * w, 0.3, 140.0, 0.012, 14, 0.02), Color(0.16, 0.2, 0.36), at(Vector3(0, 1.45 if sex == "m" else 1.41, -0.02))))
			if not _lp(): bind(parts, "pelvis", torus(0.15 * w, 0.18 * w, accent, at(Vector3(0, hip_y + 0.05, -0.03), Vector3.ZERO, Vector3(1, 1, 0.8))))
			for side in ["l", "r"]:
				var sx5 := 1.0 if side == "l" else -1.0
				bind(parts, "thigh_" + side, panel(shell(0.12, 0.3, 150.0, 0.01, 10, 0.05), Color(0.16, 0.2, 0.36), at(Vector3(0.09 * sx5, hip_y + 0.02, 0.0))))
		"censor_robe":
			for side in ["l", "r"]:
				var sx6 := 1.0 if side == "l" else -1.0
				bind(parts, "thigh_" + side, panel(shell(0.15, 0.7, 170.0, 0.01, 12, 0.06), Color(0.24, 0.26, 0.28), at(Vector3(0.08 * sx6, hip_y + 0.04, 0.0))))
				bind(parts, "thigh_" + side, panel(shell(0.15, 0.7, 170.0, 0.01, 12, 0.06), Color(0.24, 0.26, 0.28), at(Vector3(0.08 * sx6, hip_y + 0.04, 0.0), Vector3(0, 180, 0))))
			if not _lp(): bind(parts, "pelvis", torus(0.15 * w, 0.18 * w, Color(0.75, 0.6, 0.2), at(Vector3(0, hip_y + 0.05, -0.03), Vector3.ZERO, Vector3(1, 1, 0.8))))
		"sash":
			if not _lp(): bind(parts, "pelvis", torus(0.15 * w, 0.18 * w, accent, at(Vector3(0, hip_y + 0.05, -0.03), Vector3.ZERO, Vector3(1, 1.1, 0.8))))
		"civ_robe":
			# ankle-length civilian robe: wrap skirt, broad sash, crossed collar
			for side in ["l", "r"]:
				var sx7 := 1.0 if side == "l" else -1.0
				bind(parts, "thigh_" + side, panel(shell(0.15, 0.8, 175.0, 0.01, 12, 0.08), primary, at(Vector3(0.08 * sx7, hip_y + 0.05, 0.0))))
				bind(parts, "thigh_" + side, panel(shell(0.15, 0.8, 175.0, 0.01, 12, 0.08), primary, at(Vector3(0.08 * sx7, hip_y + 0.05, 0.0), Vector3(0, 180, 0))))
			if not _lp(): bind(parts, "pelvis", torus(0.14 * w, 0.19 * w, secondary, at(Vector3(0, hip_y + 0.07, -0.03), Vector3.ZERO, Vector3(1, 1.6, 0.8))))
			bind(parts, "spine_03", torus(0.13 * w, 0.16 * w, accent, at(Vector3(0.0, 1.42 if sex == "m" else 1.38, -0.02), Vector3(0, 0, 28), Vector3(1.0, 1.0, 0.75))))

## Older helmet style names from the troop data map onto head + body kits.
static func build(_kind: String, _sex: String, _hair: Color) -> Node3D:
	return null
