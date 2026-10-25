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
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
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
	# Trees
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.3
	cone.height = 3.6
	cone.radial_segments = 6
	cone.rings = 1
	var tm := StandardMaterial3D.new()
	tm.vertex_color_use_as_albedo = true
	tm.roughness = 1.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = cone
	mm.instance_count = trees.size()
	for i in trees.size():
		var t: Array = trees[i]
		var s: float = t[1]
		var xf := Transform3D(Basis().scaled(Vector3(s, s, s)), t[0] + Vector3(0, 1.8 * s, 0))
		mm.set_instance_transform(i, xf)
		var col := Color(0.14, 0.32, 0.14)
		match t[2]:
			"swamp": col = Color(0.2, 0.26, 0.14)
			"volcanic": col = Color(0.25, 0.2, 0.15)
			"highland": col = Color(0.2, 0.36, 0.2)
		mm.set_instance_color(i, col.lightened(rng.randf_range(-0.1, 0.15)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = tm
	parent.add_child(mmi)
	# Rocks
	var rock := SphereMesh.new()
	rock.radius = 1.0
	rock.height = 1.4
	rock.radial_segments = 6
	rock.rings = 3
	var rmm := MultiMesh.new()
	rmm.transform_format = MultiMesh.TRANSFORM_3D
	rmm.use_colors = true
	rmm.mesh = rock
	rmm.instance_count = rocks.size()
	for i in rocks.size():
		var r: Array = rocks[i]
		var s: float = r[1]
		var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * 0.8, s)), r[0])
		rmm.set_instance_transform(i, xf)
		rmm.set_instance_color(i, Color(0.45, 0.42, 0.38) if r[2] == "mountain" else Color(0.85, 0.9, 0.95))
	var rmi := MultiMeshInstance3D.new()
	rmi.multimesh = rmm
	rmi.material_override = tm
	parent.add_child(rmi)

# ---------------------------------------------------------------------------
# Settlements
# ---------------------------------------------------------------------------
static func culture_palette(culture: String) -> Dictionary:
	match culture:
		"fire": return {"wall": Color(0.35, 0.22, 0.18), "house": Color(0.75, 0.62, 0.5), "roof": Color(0.6, 0.12, 0.08), "accent": Color(0.85, 0.65, 0.2)}
		"earth": return {"wall": Color(0.62, 0.56, 0.45), "house": Color(0.82, 0.76, 0.62), "roof": Color(0.2, 0.42, 0.2), "accent": Color(0.75, 0.62, 0.25)}
		"omashu": return {"wall": Color(0.58, 0.55, 0.48), "house": Color(0.8, 0.74, 0.62), "roof": Color(0.3, 0.42, 0.18), "accent": Color(0.55, 0.38, 0.62)}
		"kyoshi": return {"wall": Color(0.45, 0.35, 0.22), "house": Color(0.6, 0.45, 0.3), "roof": Color(0.25, 0.45, 0.25), "accent": Color(0.85, 0.7, 0.2)}
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
	var d: Dictionary = Data.settlements[sid]
	var root := Node3D.new()
	root.name = sid
	var culture: String = d.culture
	var pal := culture_palette(culture)
	var igloo := culture in ["north", "south"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sid)
	match d.type:
		"town":
			# ring wall
			var r := 6.5
			var segs := 10
			for i in segs:
				var a := TAU * i / segs
				var p := Vector3(cos(a) * r, 1.0, sin(a) * r)
				var w := box(Vector3(4.3, 2.0, 0.6), pal.wall, p)
				w.rotation.y = -a + PI / 2.0
				root.add_child(w)
				root.add_child(cyl(0.6, 0.7, 2.8, pal.wall, Vector3(cos(a + PI / segs) * r, 1.4, sin(a + PI / segs) * r), 8))
			for i in 9:
				var a2 := rng.randf() * TAU
				var rr := rng.randf_range(1.5, 4.8)
				_house(root, pal, Vector3(cos(a2) * rr, 0, sin(a2) * rr), rng.randf_range(1.2, 1.8), igloo)
			# central tower / palace
			if igloo:
				root.add_child(sphere(2.4, pal.house, Vector3.ZERO, true))
				root.add_child(cyl(0.3, 0.6, 6.0, pal.house, Vector3(0, 3.0, 0), 8))
			else:
				for lvl in 3:
					var s := 3.0 - lvl * 0.8
					var y := lvl * 1.8
					root.add_child(box(Vector3(s, 1.4, s), pal.house, Vector3(0, y + 0.7, 0)))
					root.add_child(roof(s * 1.5, s * 1.5, 0.8, pal.roof, Vector3(0, y + 1.8, 0)))
		"castle":
			var s := 4.5
			for i in 4:
				var corner := Vector3((1 if i % 2 == 0 else -1) * s, 0, (1 if i < 2 else -1) * s)
				root.add_child(cyl(0.9, 1.0, 4.0, pal.wall, corner + Vector3(0, 2.0, 0), 8))
				if not igloo:
					root.add_child(cyl(0.0, 1.3, 1.2, pal.roof, corner + Vector3(0, 4.6, 0), 8))
			root.add_child(box(Vector3(s * 2, 2.6, 0.7), pal.wall, Vector3(0, 1.3, s)))
			root.add_child(box(Vector3(s * 2, 2.6, 0.7), pal.wall, Vector3(0, 1.3, -s)))
			root.add_child(box(Vector3(0.7, 2.6, s * 2), pal.wall, Vector3(s, 1.3, 0)))
			root.add_child(box(Vector3(0.7, 2.6, s * 2), pal.wall, Vector3(-s, 1.3, 0)))
			root.add_child(box(Vector3(3, 4.5, 3), pal.wall.darkened(0.1), Vector3(0, 2.25, 0)))
			if not igloo:
				root.add_child(roof(4.2, 4.2, 1.4, pal.roof, Vector3(0, 5.2, 0)))
		"village":
			for i in 6:
				var a3 := rng.randf() * TAU
				var rr2 := rng.randf_range(1.0, 4.5)
				_house(root, pal, Vector3(cos(a3) * rr2, 0, sin(a3) * rr2), rng.randf_range(0.9, 1.3), igloo)
			# fields
			if not igloo and culture != "swamp":
				for i in 3:
					var fp := Vector3(rng.randf_range(-6, 6), 0.05, rng.randf_range(-6, 6))
					root.add_child(box(Vector3(3, 0.1, 2), Color(0.65, 0.6, 0.25), fp))
		"temple", "ruin":
			if d.type == "temple":
				for i in 4:
					var a4 := TAU * i / 4.0
					var p2 := Vector3(cos(a4) * 2.5, 0, sin(a4) * 2.5)
					var h := rng.randf_range(4.0, 7.5)
					root.add_child(cyl(0.7, 0.9, h, pal.wall, p2 + Vector3(0, h / 2.0, 0), 10))
					root.add_child(cyl(0.0, 1.3, 2.2, pal.roof, p2 + Vector3(0, h + 1.1, 0), 10))
				root.add_child(cyl(1.2, 1.6, 9.0, pal.wall, Vector3(0, 4.5, 0), 10))
				root.add_child(cyl(0.0, 2.0, 3.0, pal.roof, Vector3(0, 10.5, 0), 10))
			elif sid == "wan_shi_tong":
				root.add_child(cyl(1.0, 1.4, 7.0, Color(0.45, 0.35, 0.25), Vector3(0, 3.5, 0), 8))
				root.add_child(cyl(0.0, 2.0, 2.5, Color(0.3, 0.25, 0.2), Vector3(0, 8.2, 0), 8))
			elif sid == "red_lantern_den":
				for i in 5:
					var tp := Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-4, 4))
					root.add_child(cyl(0.4, 0.5, 7.0, Color(0.35, 0.25, 0.15), tp + Vector3(0, 3.5, 0), 6))
					root.add_child(sphere(2.0, Color(0.15, 0.35, 0.15), tp + Vector3(0, 7.5, 0)))
					root.add_child(box(Vector3(2.0, 0.8, 2.0), Color(0.5, 0.38, 0.22), tp + Vector3(0, 5.5, 0)))
			else:
				for i in 6:
					var bp := Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5))
					var bh := rng.randf_range(0.6, 2.5)
					root.add_child(box(Vector3(rng.randf_range(1, 3), bh, 0.6), Color(0.45, 0.43, 0.4), bp + Vector3(0, bh / 2.0, 0), Vector3(0, rng.randf() * 180, 0)))
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
