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
## The terrain as one mesh, every other grid sample (4 map units).
static func terrain_mesh() -> ArrayMesh:
	if _terrain_mesh != null:
		return _terrain_mesh
	Terrain.ensure()
	var stride := 2
	var gw := (Terrain.GW - 1) / stride + 1
	var gh := (Terrain.GH - 1) / stride + 1
	var verts := PackedVector3Array()
	verts.resize(gw * gh)
	for gy in gh:
		for gx in gw:
			var h := Terrain.grid_height(gx * stride, gy * stride)
			verts[gy * gw + gx] = Vector3(gx * stride * Terrain.CELL, maxf(h, -2.0), gy * stride * Terrain.CELL)
	var idx := PackedInt32Array()
	idx.resize((gw - 1) * (gh - 1) * 6)
	var k := 0
	for gy in gh - 1:
		for gx in gw - 1:
			var i0 := gy * gw + gx
			idx[k] = i0
			idx[k + 1] = i0 + 1
			idx[k + 2] = i0 + gw
			idx[k + 3] = i0 + 1
			idx[k + 4] = i0 + gw + 1
			idx[k + 5] = i0 + gw
			k += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = idx
	_terrain_mesh = ArrayMesh.new()
	_terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _terrain_mesh

## The world map's look: "painted" (the hand-painted fantasy map, after the
## series' world maps; the default), "atlas" (painted relief), "chart" (an old
## ink-and-parchment chart) or "ink" (ink wash on rice paper).
## Settings > Map style. The index is the shaders' style number.
const MAP_STYLES := ["atlas", "chart", "ink", "painted"]
const PAINTED_FILE := "res://assets/world/painted.png"
static var terrain_material: ShaderMaterial
static var sea_material: ShaderMaterial
static var vegetation: Node3D

static func map_style() -> String:
	var st: String = GS.settings.get("map_style", "painted")
	return st if st in MAP_STYLES else "painted"

static func build_terrain(parent: Node3D) -> void:
	var ht := Terrain.height_texture()
	var it := Terrain.info_texture()
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = load("res://shaders/map_terrain.gdshader")
	terrain_material.set_shader_parameter("height_tex", ht)
	terrain_material.set_shader_parameter("info_near", it)
	terrain_material.set_shader_parameter("info_lin", it)
	var painted := _painted_texture()
	terrain_material.set_shader_parameter("painted_tex", painted)
	var mi := MeshInstance3D.new()
	mi.mesh = terrain_mesh()
	mi.material_override = terrain_material
	parent.add_child(mi)
	# Sea: one plane over the whole map and beyond, drawn by its own shader
	sea_material = ShaderMaterial.new()
	sea_material.shader = load("res://shaders/map_sea.gdshader")
	sea_material.set_shader_parameter("height_tex", ht)
	sea_material.set_shader_parameter("info_lin", it)
	sea_material.set_shader_parameter("painted_tex", painted)
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(Data.MAP_W * 3.0, Data.MAP_H * 3.0)
	sea.mesh = pm
	sea.position = Vector3(Data.MAP_W / 2.0, 0.0, Data.MAP_H / 2.0)
	sea.material_override = sea_material
	parent.add_child(sea)
	vegetation = Node3D.new()
	parent.add_child(vegetation)
	build_vegetation(vegetation)
	apply_style()
	update_borders()

## Political borders: send every held settlement's position and its holder's
## colour to the terrain shader (call when settlements change hands).
static func update_borders() -> void:
	if terrain_material == null:
		return
	var pos := PackedVector2Array()
	var col := PackedColorArray()
	var ids := Data.settlements.keys()
	ids.sort()
	for sid in ids:
		if Data.settlements[sid].type == "ruin" or not GS.settlements.has(sid):
			continue
		pos.append(Data.settlements[sid].pos)
		col.append(Data.factions.get(GS.settlements[sid].faction, Data.factions.neutral).color)
		if pos.size() >= 128:
			break
	terrain_material.set_shader_parameter("site_pos", pos)
	terrain_material.set_shader_parameter("site_color", col)
	terrain_material.set_shader_parameter("site_count", pos.size())
	terrain_material.set_shader_parameter("borders", 1.0 if GS.settings.get("map_borders", true) else 0.0)

static var _painted: ImageTexture

## The painted map (tools/paint_map.py), read straight from the PNG.
static func _painted_texture() -> ImageTexture:
	if _painted != null:
		return _painted
	var img := Image.new()
	if img.load_png_from_buffer(FileAccess.get_file_as_bytes(PAINTED_FILE)) != OK:
		return null
	img.generate_mipmaps()
	_painted = ImageTexture.create_from_image(img)
	return _painted

## Switch the map's style in place.
static func apply_style() -> void:
	var i := MAP_STYLES.find(map_style())
	if terrain_material != null:
		terrain_material.set_shader_parameter("style", i)
		sea_material.set_shader_parameter("style", i)
	update_zoom(_zoom)

static var _zoom := 90.0

## Trees on the map only up close and only in the painted atlas (the chart
## and the ink wash draw their own); from far away the shader's canopy reads
## better than thousands of tiny models.
static func update_zoom(cam_dist: float) -> void:
	_zoom = cam_dist
	if vegetation != null and is_instance_valid(vegetation):
		vegetation.visible = map_style() == "atlas" and cam_dist < 240.0

static func set_daylight(d: float) -> void:
	if terrain_material != null:
		terrain_material.set_shader_parameter("daylight", d)
		sea_material.set_shader_parameter("daylight", d)

## Trees and rocks for the painted atlas, clustered where the baked forest is
## dense and kept off settlements.
static func build_vegetation(parent: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var trees := []
	var rocks := []
	var near := {}
	for sid in Data.settlements:
		var c: Vector2 = Data.settlements[sid].pos
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				near[Vector2i(int(c.x / 14.0) + dx, int(c.y / 14.0) + dy)] = c
	var step := 5.0
	var y := 0.0
	while y < Data.MAP_H:
		var x := 0.0
		while x < Data.MAP_W:
			var p := Vector2(x + rng.randf_range(-2.0, 2.0), y + rng.randf_range(-2.0, 2.0))
			x += step
			if not Terrain.is_land(p):
				continue
			var b := Terrain.biome(p)
			var f := Terrain.forest(p)
			var want := 0.0
			match b:
				"forest", "swamp": want = 0.25 + f * 0.6
				"grass", "highland": want = f * 0.3
				"volcanic": want = 0.04
				"mountain": want = 0.08
				"snow": want = 0.02
			if rng.randf() > want:
				continue
			var kc := Vector2i(int(p.x / 14.0), int(p.y / 14.0))
			if near.has(kc) and near[kc].distance_to(p) < 12.0:
				continue
			var h := Terrain.height(p)
			if b == "mountain" or b == "snow":
				rocks.append([Vector3(p.x, h, p.y), rng.randf_range(0.8, 2.0), b])
			else:
				trees.append([Vector3(p.x, h, p.y), rng.randf_range(0.8, 1.4), b])
		y += step
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

## First mesh of a nature-kit model with model materials, and its local transform.
static func _nature_mesh(name: String) -> Array:
	if _nature_cache.has(name):
		return _nature_cache[name]
	var inst: Node3D = load("res://assets/nature/%s.gltf" % name).instantiate()
	var mi: MeshInstance3D = inst.find_children("*", "MeshInstance3D", true, false)[0]
	var mesh: ArrayMesh = mi.mesh.duplicate()
	var CBs = load("res://scripts/actors/character_builder.gd")
	for i in mesh.get_surface_count():
		mesh.surface_set_material(i, CBs.model_material(mesh.surface_get_material(i), {"saturation": 1.1, "outline": false}))
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

## A ring of wall segments around the origin at height y.
static func _wall_ring(Arch, culture: String, mini: Callable, k: float, r: float, n: int, h: float, y: float) -> void:
	var chord := 2.0 * r * sin(PI / n) / k * 1.06
	for i in n:
		var a := TAU * (i + 0.5) / n
		mini.call(Arch.wall(culture, chord, h, -a + PI / 2.0), Vector3(cos(a) * r, y, sin(a) * r), k)

## Omashu: a mountain cut into four terraces with a spiralling delivery chute,
## the palace on the summit.
static func _omashu_model(root: Node3D, rng: RandomNumberGenerator, mini: Callable, house: Callable, Arch, culture: String, k: float) -> void:
	# the city is built on the mountain: four terraces stepping up a rocky cone,
	# the palace on the summit, a chute spiralling down the face
	var radii := [9.0, 7.0, 5.0, 3.2]
	var tops := [1.6, 3.3, 5.0, 6.7]
	var stone := Color(0.5, 0.47, 0.42)
	# a broken rock skirt around the foot and boulders along every terrace edge
	root.add_child(cyl(radii[0] + 0.5, radii[0] + 2.4, 0.9, Color(0.44, 0.42, 0.38), Vector3(0, 0.45, 0), 16))
	for i in 4:
		root.add_child(cyl(radii[i], radii[i] + 0.9, tops[i], stone * (0.88 + 0.06 * i), Vector3(0, tops[i] * 0.5, 0), 16))
		root.add_child(cyl(radii[i] - 0.45, radii[i] - 0.45, 0.06, Color(0.42, 0.56, 0.3), Vector3(0, tops[i] + 0.01, 0), 16))
		for j in 14 + (3 - i) * 3:
			var a := TAU * j / float(14 + (3 - i) * 3) + rng.randf_range(-0.12, 0.12)
			var rr := rng.randf_range(0.5, 1.0)
			var rh := rng.randf_range(0.8, 1.7)
			root.add_child(cyl(rr * 0.35, rr, rh, Color(0.52, 0.5, 0.46) * rng.randf_range(0.8, 1.1), Vector3(cos(a) * (radii[i] + 0.6), tops[i] - rh * 0.4, sin(a) * (radii[i] + 0.6)), 6))
	# the summit rock above the palace
	root.add_child(cyl(1.2, 3.0, 2.4, Color(0.5, 0.48, 0.44), Vector3(0, tops[3] + 1.2, -2.4), 7))
	_wall_ring(Arch, culture, mini, k, 8.7, 10, 6.0, tops[0])
	for i in 4:
		var n: int = 8 - i
		for j in n:
			var a2 := TAU * (j + 0.5) / n + i * 0.3
			var rr2: float = radii[i] - 1.7
			if i == 3:
				rr2 = 1.4
				if j > 3:
					continue
			house.call(Vector3(cos(a2) * rr2, tops[i], sin(a2) * rr2), rng.randf_range(5.5, 7.5), 5.0, 1 + int(rng.randf() < 0.3), round(a2 / (PI * 0.5)) * PI * 0.5)
	house.call(Vector3(0, tops[3], 0.4), 12.0, 9.0, 3, 0.0)
	# the chutes, spiralling down the face of the mountain
	for sgn in [0.0, PI]:
		var prev := Vector3.ZERO
		for j in 19:
			var t: float = j / 18.0
			var ang: float = sgn + 0.4 + t * 5.4
			var rad: float = lerpf(3.4, 9.6, t)
			var pt := Vector3(cos(ang) * rad, lerpf(7.4, 1.9, t), sin(ang) * rad)
			if j > 0:
				var seg := box(Vector3(0.6, 0.22, prev.distance_to(pt) + 0.05), Color(0.66, 0.54, 0.4), (prev + pt) * 0.5)
				seg.basis = Basis.looking_at(pt - prev, Vector3.UP)
				root.add_child(seg)
			prev = pt

## Ba Sing Se: three concentric walled rings, the palace at the heart.
static func _ba_sing_se_model(root: Node3D, rng: RandomNumberGenerator, mini: Callable, house: Callable, Arch, culture: String, k: float) -> void:
	var rings := [[9.0, 14, 6.5, 0.0], [6.1, 10, 5.5, 0.35], [3.4, 7, 4.5, 0.7]]
	for ring in rings:
		root.add_child(cyl(ring[0], ring[0] + 0.3, ring[3] + 0.04, Color(0.55, 0.62, 0.42) * (1.0 - ring[3] * 0.08), Vector3(0, (ring[3] + 0.04) * 0.5, 0), 24))
		_wall_ring(Arch, culture, mini, k, ring[0], ring[1], ring[2], ring[3])
	var lows := [[7.4, 10], [4.7, 7]]
	for lw in lows:
		for j in int(lw[1]):
			var a := TAU * (j + 0.5) / float(lw[1])
			house.call(Vector3(cos(a) * lw[0], 0.35 if lw[0] < 6.0 else 0.0, sin(a) * lw[0]), rng.randf_range(5.5, 7.0), 4.5, 1, round(a / (PI * 0.5)) * PI * 0.5)
	house.call(Vector3(0, 0.7, 0), 12.0, 9.0, 3, 0.0)

## Caldera: the city sits inside the rim of a volcano's crater.
static func _crater_rim(root: Node3D, rng: RandomNumberGenerator) -> void:
	root.add_child(cyl(9.5, 12.0, 0.8, Color(0.26, 0.22, 0.21), Vector3(0, 0.4, 0), 18))
	for i in 18:
		var a := TAU * i / 18.0 + rng.randf_range(-0.1, 0.1)
		var h := rng.randf_range(2.2, 3.6)
		root.add_child(cyl(0.5, 1.7, h, Color(0.3, 0.25, 0.24) * rng.randf_range(0.85, 1.1), Vector3(cos(a) * 9.4, h * 0.5, sin(a) * 9.4), 6))
	root.add_child(cyl(1.6, 1.8, 0.1, Color(0.95, 0.35, 0.1), Vector3(0, 0.07, 6.2), 10))

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
			if sid == "omashu":
				_omashu_model(root, rng, mini, house, Arch, culture, k)
			elif sid == "ba_sing_se":
				_ba_sing_se_model(root, rng, mini, house, Arch, culture, k)
			else:
				var r := 6.5
				for i in 8:
					var a := TAU * i / 8.0
					var wall = Arch.wall(culture, 17.0, 6.0, -a + PI / 2.0)
					mini.call(wall, Vector3(cos(a + PI / 8.0) * r, 0, sin(a + PI / 8.0) * r), k)
				house.call(Vector3(0, 0, -1.0), 14.0, 10.0, 3, 0.0)
				for i in 6:
					var a2 := TAU * (i + 0.5) / 6.0
					house.call(Vector3(cos(a2) * 3.8, 0, sin(a2) * 3.8), rng.randf_range(6.0, 8.0), 5.5, 1 + int(rng.randf() < 0.3), round(a2 / (PI * 0.5)) * PI * 0.5)
				if sid == "caldera":
					_crater_rim(root, rng)
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
