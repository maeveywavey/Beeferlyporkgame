extends RefCounted
## Builds the 3D world map: terrain mesh, sea, vegetation, settlement and
## party models. Everything is made from primitives so no art assets are needed.

const Terrain = preload("res://scripts/core/terrain.gd")
const Actor = preload("res://scripts/actors/actor.gd")
const Looks = preload("res://scripts/actors/looks.gd")

static var _terrain_mesh: ArrayMesh
static var _mats := {}

static func mat(c: Color, rough: float = 0.9, unshaded: bool = false) -> StandardMaterial3D:
	var key := "%s_%s_%s" % [c.to_html(), rough, unshaded]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[key] = m
	return m

static func mesh_node(mesh: Mesh, color: Color, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi

static func box(size: Vector3, color: Color, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return mesh_node(b, color, pos, rot_deg)

static func cyl(r_top: float, r_bot: float, h: float, color: Color, pos: Vector3 = Vector3.ZERO, segs: int = 12) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return mesh_node(c, color, pos)

static func sphere(r: float, color: Color, pos: Vector3 = Vector3.ZERO, hemi: bool = false) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0 if not hemi else r
	s.is_hemisphere = hemi
	s.radial_segments = 16
	s.rings = 8
	return mesh_node(s, color, pos)

static func roof(w: float, d: float, h: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var p := PrismMesh.new()
	p.size = Vector3(w, h, d)
	return mesh_node(p, color, pos)

# ---------------------------------------------------------------------------
# Terrain
# ---------------------------------------------------------------------------
static func terrain_mesh() -> ArrayMesh:
	if _terrain_mesh != null:
		return _terrain_mesh
	Terrain.ensure()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gw := Terrain.GW
	var gh := Terrain.GH
	var cell := Terrain.CELL
	var tint := FastNoiseLite.new()
	tint.seed = 7
	tint.frequency = 0.05
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	verts.resize(gw * gh)
	cols.resize(gw * gh)
	for gy in gh:
		for gx in gw:
			var h := Terrain.grid_height(gx, gy)
			var b := Terrain.grid_biome(gx, gy)
			var c: Color = Terrain.BIOME_COLOR[b]
			if b == "ocean":
				c = Color(0.55, 0.6, 0.5).lerp(Color(0.05, 0.12, 0.25), clampf(-h / 5.0, 0.0, 1.0))
			else:
				if h > 7.0 and b != "snow" and b != "desert":
					c = c.lerp(Terrain.BIOME_COLOR.mountain, clampf((h - 7.0) / 6.0, 0.0, 1.0))
				if h > 14.0:
					c = c.lerp(Color(0.95, 0.95, 0.97), clampf((h - 14.0) / 5.0, 0.0, 0.9))
			var n := tint.get_noise_2d(gx * 3.0, gy * 3.0) * 0.08
			c = Color(clampf(c.r + n, 0, 1), clampf(c.g + n, 0, 1), clampf(c.b + n * 0.5, 0, 1))
			var i := gy * gw + gx
			verts[i] = Vector3(gx * cell, h, gy * cell)
			cols[i] = c
	for gy in gh - 1:
		for gx in gw - 1:
			var i0 := gy * gw + gx
			var i1 := i0 + 1
			var i2 := i0 + gw
			var i3 := i2 + 1
			for idx in [i0, i1, i2, i1, i3, i2]:
				st.set_color(cols[idx])
				st.add_vertex(verts[idx])
	st.generate_normals()
	_terrain_mesh = st.commit()
	return _terrain_mesh

static func build_terrain(parent: Node3D) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = terrain_mesh()
	# painted like the series' map backgrounds: vertex colours plus soft brushwork
	var m: ShaderMaterial = load("res://scripts/town/arch.gd").material(false).duplicate()
	m.set_shader_parameter("brush_scale", 0.03)
	m.set_shader_parameter("brush_strength", 0.12)
	mi.material_override = m
	parent.add_child(mi)
	# Sea
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(Data.MAP_W * 3.0, Data.MAP_H * 3.0)
	sea.mesh = pm
	sea.position = Vector3(Data.MAP_W / 2.0, 0.0, Data.MAP_H / 2.0)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.12, 0.35, 0.6, 0.72)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.roughness = 0.15
	sm.metallic = 0.2
	sea.material_override = sm
	parent.add_child(sea)
	build_vegetation(parent)

static func build_vegetation(parent: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var trees := []
	var rocks := []
	var cell := Terrain.CELL
	for gy in Terrain.GH:
		for gx in Terrain.GW:
			var b := Terrain.grid_biome(gx, gy)
			var count := 0
			match b:
				"forest": count = 3
				"swamp": count = 2
				"highland": count = 1 if rng.randf() < 0.5 else 0
				"grass": count = 1 if rng.randf() < 0.12 else 0
				"volcanic": count = 1 if rng.randf() < 0.15 else 0
				"mountain": count = 1 if rng.randf() < 0.35 else 0
				"snow": count = 1 if rng.randf() < 0.05 else 0
			for i in count:
				var p := Vector2(gx * cell + rng.randf_range(-4, 4), gy * cell + rng.randf_range(-4, 4))
				if not Terrain.is_land(p):
					continue
				var too_close := false
				for sid in Data.settlements:
					if Data.settlements[sid].pos.distance_to(p) < 13.0:
						too_close = true
						break
				if too_close:
					continue
				var h := Terrain.height(p)
				if b == "mountain" or b == "snow":
					rocks.append([Vector3(p.x, h, p.y), rng.randf_range(0.8, 2.0), b])
				else:
					trees.append([Vector3(p.x, h, p.y), rng.randf_range(0.8, 1.4), b])
	# Trees and rocks: CC0 nature-kit meshes in multimeshes, one per species
	var species := {}
	for t in trees:
		var names: Array
		match t[2]:
			"forest": names = ["CommonTree_1", "CommonTree_3", "Pine_1"]
			"swamp": names = ["TwistedTree_2", "TwistedTree_4"]
			"volcanic": names = ["DeadTree_4", "DeadTree_1"]
			"highland": names = ["Pine_2", "Pine_4"]
			_: names = ["CommonTree_1", "CommonTree_5"]
		var nm: String = names[rng.randi() % names.size()]
		if not species.has(nm):
			species[nm] = []
		species[nm].append(t)
	for r in rocks:
		var rn: String = ["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"][rng.randi() % 3]
		if not species.has(rn):
			species[rn] = []
		species[rn].append(r)
	for nm in species:
		var src := _nature_mesh(nm)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = src[0]
		var list: Array = species[nm]
		mm.instance_count = list.size()
		var is_rock: bool = nm.begins_with("Rock")
		for i in list.size():
			var t2: Array = list[i]
			var sc: float = t2[1] * (0.3 if not is_rock else 0.55)
			var xf = Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * sc), t2[0]) * src[1]
			mm.set_instance_transform(i, xf)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		parent.add_child(mmi)

static var _nature_cache := {}

## First mesh of a nature-kit model with toon materials, and its local transform.
static func _nature_mesh(name: String) -> Array:
	if _nature_cache.has(name):
		return _nature_cache[name]
	var inst: Node3D = load("res://assets/nature/%s.gltf" % name).instantiate()
	var mi: MeshInstance3D = inst.find_children("*", "MeshInstance3D", true, false)[0]
	var mesh: ArrayMesh = mi.mesh.duplicate()
	var CBs = load("res://scripts/actors/character_builder.gd")
	for i in mesh.get_surface_count():
		mesh.surface_set_material(i, CBs.toon_from(mesh.surface_get_material(i), {"saturation": 1.1, "outline": false}))
	var xf: Transform3D = inst.transform.affine_inverse() * mi.global_transform if mi.is_inside_tree() else _rel_xf(inst, mi)
	inst.free()
	_nature_cache[name] = [mesh, xf]
	return _nature_cache[name]

static func _rel_xf(root: Node3D, n: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf

# ---------------------------------------------------------------------------
# Settlements
# ---------------------------------------------------------------------------
static func culture_palette(culture: String) -> Dictionary:
	match culture:
		"fire": return {"wall": Color(0.35, 0.22, 0.18), "house": Color(0.75, 0.62, 0.5), "roof": Color(0.6, 0.12, 0.08), "accent": Color(0.85, 0.65, 0.2)}
		"earth": return {"wall": Color(0.62, 0.56, 0.45), "house": Color(0.82, 0.76, 0.62), "roof": Color(0.2, 0.42, 0.2), "accent": Color(0.75, 0.62, 0.25)}
		"omashu": return {"wall": Color(0.58, 0.55, 0.48), "house": Color(0.8, 0.74, 0.62), "roof": Color(0.3, 0.42, 0.18), "accent": Color(0.55, 0.38, 0.62)}
		"hamakaze": return {"wall": Color(0.45, 0.35, 0.22), "house": Color(0.6, 0.45, 0.3), "roof": Color(0.22, 0.28, 0.4), "accent": Color(0.62, 0.3, 0.18)}
		"north", "south": return {"wall": Color(0.85, 0.92, 0.98), "house": Color(0.9, 0.95, 1.0), "roof": Color(0.3, 0.5, 0.8), "accent": Color(0.2, 0.4, 0.75)}
		"swamp": return {"wall": Color(0.3, 0.25, 0.15), "house": Color(0.4, 0.32, 0.2), "roof": Color(0.3, 0.38, 0.2), "accent": Color(0.4, 0.5, 0.3)}
		"air": return {"wall": Color(0.85, 0.82, 0.75), "house": Color(0.88, 0.85, 0.78), "roof": Color(0.25, 0.45, 0.65), "accent": Color(0.9, 0.55, 0.15)}
	return {"wall": Color(0.6, 0.6, 0.6), "house": Color(0.8, 0.8, 0.8), "roof": Color(0.4, 0.3, 0.2), "accent": Color(0.7, 0.6, 0.3)}

static func _house(parent: Node3D, pal: Dictionary, pos: Vector3, size: float, igloo: bool) -> void:
	if igloo:
		parent.add_child(sphere(size * 0.7, pal.house, pos, true))
	else:
		parent.add_child(box(Vector3(size, size * 0.7, size * 0.8), pal.house, pos + Vector3(0, size * 0.35, 0)))
		parent.add_child(roof(size * 1.25, size * 1.0, size * 0.5, pal.roof, pos + Vector3(0, size * 0.95, 0)))

static func build_settlement(sid: String) -> Node3D:
	var Arch = load("res://scripts/town/arch.gd")
	var d: Dictionary = Data.settlements[sid]
	var root := Node3D.new()
	root.name = sid
	var culture: String = d.culture
	var ice := culture in ["north", "south"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sid)
	var k := 0.45   # miniature scale: settlements are drawn larger than life so they read
	var mini := func(n: Node3D, pos: Vector3, sc: float) -> void:
		n.position = pos
		n.scale = Vector3.ONE * sc
		root.add_child(n)
	var house := func(pos: Vector3, w: float, dd: float, floors: int, rot: float) -> void:
		var n: Node3D
		if ice:
			n = Arch.ice_dome(minf(w, dd) * 0.55, rot)
		elif culture == "swamp":
			n = Arch.stilt_hut(w, dd, rot)
		elif culture == "air":
			n = Arch.air_tower(1.6, 5.0 + floors * 2.0)
		else:
			n = Arch.hall(culture, w, dd, floors, rot)
		mini.call(n, pos, k)
	match d.type:
		"town":
			var r := 6.5
			for i in 8:
				var a := TAU * i / 8.0
				var wall = Arch.wall(culture, 17.0, 6.0, -a + PI / 2.0)
				mini.call(wall, Vector3(cos(a + PI / 8.0) * r, 0, sin(a + PI / 8.0) * r), k)
			house.call(Vector3(0, 0, -1.0), 14.0, 10.0, 3, 0.0)
			for i in 6:
				var a2 := TAU * (i + 0.5) / 6.0
				house.call(Vector3(cos(a2) * 3.8, 0, sin(a2) * 3.8), rng.randf_range(6.0, 8.0), 5.5, 1 + int(rng.randf() < 0.3), round(a2 / (PI * 0.5)) * PI * 0.5)
		"castle":
			for i in 4:
				var a3 := TAU * i / 4.0 + PI / 4.0
				var wall2 = Arch.wall(culture, 18.0, 6.0, -a3 + PI / 2.0 + PI / 4.0)
				mini.call(wall2, Vector3(cos(a3 + PI / 4.0) * 4.2, 0, sin(a3 + PI / 4.0) * 4.2), k)
			house.call(Vector3.ZERO, 11.0, 9.0, 3, 0.0)
		"village":
			for i in 5:
				var a4 := TAU * i / 5.0 + rng.randf() * 0.4
				var rr := rng.randf_range(1.5, 4.0)
				house.call(Vector3(cos(a4) * rr, 0, sin(a4) * rr), rng.randf_range(5.5, 7.0), 4.8, 1, round(a4 / (PI * 0.5)) * PI * 0.5)
			if not ice and culture != "swamp":
				for i in 2:
					var fp := Vector3(rng.randf_range(-6, 6), 0.02, rng.randf_range(-6, 6))
					mini.call(Arch.paddy(10.0, 7.0, culture in ["earth", "fire", "hamakaze", "omashu"]), fp, k)
		"temple":
			var hall = Arch.hall("air", 14.0, 10.0, 3, 0.0, {"floor_h": 3.0})
			mini.call(hall, Vector3(0, 0, -0.5), k)
			for i in 4:
				var a5 := TAU * i / 4.0 + PI / 4.0
				mini.call(Arch.air_tower(2.4, 9.0 + i), Vector3(cos(a5) * 4.0, 0, sin(a5) * 4.0), k)
		"ruin":
			if sid == "wan_shi_tong":
				mini.call(Arch.air_tower(3.0, 14.0), Vector3.ZERO, k)
			elif sid == "red_lantern_den":
				for i in 4:
					var a6 := TAU * i / 4.0
					mini.call(Arch.stilt_hut(5.0, 4.0, a6), Vector3(cos(a6) * 3.0, 0, sin(a6) * 3.0), k)
					var ln = Arch.lantern(Color(0.95, 0.2, 0.12))
					mini.call(ln, Vector3(cos(a6) * 4.5, 0, sin(a6) * 4.5), k * 1.5)
			else:
				var b = Arch.Builder.new()
				for i in 7:
					var bp := Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5))
					var bh := rng.randf_range(0.6, 2.5)
					b.box(bp + Vector3(0, bh / 2.0, 0), Vector3(rng.randf_range(1, 3), bh, 0.6), Color(0.6, 0.57, 0.52), rng.randf() * PI)
				var mi := MeshInstance3D.new()
				mi.mesh = b.commit()
				mi.material_override = Arch.material(true)
				root.add_child(mi)
	return root

## Banner showing a settlement's current faction; returned so it can be recoloured.
static func build_banner(height: float = 7.0) -> Node3D:
	var root := Node3D.new()
	root.add_child(cyl(0.12, 0.12, height, Color(0.3, 0.2, 0.1), Vector3(0, height / 2.0, 0), 6))
	var flag := box(Vector3(2.2, 1.4, 0.08), Color.WHITE, Vector3(1.15, height - 0.8, 0))
	flag.name = "Flag"
	flag.material_override = StandardMaterial3D.new()
	root.add_child(flag)
	return root

static func set_banner_color(banner: Node3D, c: Color) -> void:
	var f: MeshInstance3D = banner.get_node("Flag")
	(f.material_override as StandardMaterial3D).albedo_color = c

# ---------------------------------------------------------------------------
# Parties
# ---------------------------------------------------------------------------
static func build_party(p: Dictionary) -> Node3D:
	var root := Node3D.new()
	var fc: Color = Data.factions.get(p.faction, Data.factions.neutral).color
	var trim: Color = Data.factions.get(p.faction, Data.factions.neutral).trim
	if p.kind == "pilgrim":
		# A sky bison carrying Air Nomad pilgrims (rigged animal, legs paddling the air)
		var bison := Node3D.new()
		bison.name = "Body"
		bison.position.y = 7.0
		var m: Dictionary = load("res://scripts/actors/mount.gd").build("bison")
		m.root.scale = Vector3.ONE * 0.9
		bison.add_child(m.root)
		load("res://scripts/actors/mount.gd").animate(m, 2.0)
		# two monks riding in the saddle
		for i in 2:
			var monk = Actor.new()
			monk.setup(Looks.troop_look("an_monk", RandomNumberGenerator.new()))
			monk.set_stance("ride")
			monk.position = Vector3((i - 0.5) * 0.7, m.seat * 0.9 - 0.4, -0.3 + i * 0.5)
			bison.add_child(monk)
		root.add_child(bison)
		return root
	var body_node := Node3D.new()
	body_node.name = "Body"
	root.add_child(body_node)
	var scale := 1.0
	match p.kind:
		"lord": scale = 1.25
		"player": scale = 1.25
		"villager": scale = 0.85
	# A rigged character stands in for the party (1.4x scale so it reads at map distance)
	var actor = Actor.new()
	actor.name = "Actor"
	actor.setup(Looks.party_look(p))
	actor.scale = Vector3.ONE * 1.4 * scale
	root.add_child(actor)
	if p.kind == "caravan":
		body_node.add_child(box(Vector3(1.6, 1.0, 2.4), Color(0.55, 0.4, 0.25), Vector3(1.4, 0.7, 0)))
		body_node.add_child(cyl(0.45, 0.45, 0.2, Color(0.3, 0.2, 0.1), Vector3(1.4, 0.45, 1.1)))
	if p.kind in ["lord", "player", "bandit"]:
		var pole_h := 4.2 * scale
		body_node.add_child(cyl(0.07, 0.07, pole_h, Color(0.3, 0.2, 0.1), Vector3(-0.8, pole_h / 2.0, 0), 5))
		var flag_col := trim if p.kind == "lord" else (Color(0.95, 0.85, 0.3) if p.kind == "player" else Color(0.2, 0.18, 0.15))
		body_node.add_child(box(Vector3(1.4, 0.9, 0.06), flag_col, Vector3(-0.1, pole_h - 0.5, 0)))
		if p.kind == "lord":
			body_node.add_child(box(Vector3(0.5, 0.5, 0.08), fc, Vector3(-0.1, pole_h - 0.5, 0.02)))
	# Boat shown while the party sails across water
	var boat := Node3D.new()
	boat.name = "Boat"
	boat.visible = false
	var hull_c := Color(0.35, 0.22, 0.12) if p.faction != "fire_nation" else Color(0.3, 0.3, 0.32)
	var hull := box(Vector3(2.2, 0.7, 5.0), hull_c, Vector3(0, 0.1, 0))
	boat.add_child(hull)
	boat.add_child(box(Vector3(1.6, 0.4, 1.2), hull_c, Vector3(0, 0.1, 2.8), Vector3(0, 45, 0)))
	boat.add_child(cyl(0.08, 0.08, 4.5, Color(0.3, 0.2, 0.1), Vector3(0, 2.4, -0.5), 5))
	var sail_c: Color = Data.factions.get(p.faction, Data.factions.neutral).color.lightened(0.3)
	boat.add_child(box(Vector3(2.4, 2.4, 0.05), sail_c, Vector3(0, 2.8, -0.4)))
	root.add_child(boat)
	if p.kind == "player":
		var ring := TorusMesh.new()
		ring.inner_radius = 1.5
		ring.outer_radius = 1.9
		var rn := mesh_node(ring, Color(1, 0.85, 0.2), Vector3(0, 0.1, 0))
		rn.material_override = mat(Color(1, 0.85, 0.2), 0.5, true)
		root.add_child(rn)
	return root
