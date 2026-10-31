extends RefCounted
## Lays out a walkable settlement: buildings, walls, streets, props, trees,
## the places people work and the points the player can interact with. The
## plan depends on the settlement type (town, castle, village, temple) and
## culture (Earth, Omashu, Fire, Hamakaze, Water Tribes, Air Nomads, swamp).
##
## Coordinates: the settlement centre is the origin, +Z is south, where the
## player arrives.

const Arch = preload("res://scripts/town/arch.gd")
const CB = preload("res://scripts/actors/character_builder.gd")

var root: Node3D
var culture := "earth"
var kind := "town"
var sid := ""
var rng := RandomNumberGenerator.new()
var obstacles: Array = []      # {"c": Vector2, "h": Vector2} rects, {"c": Vector2, "r": float} circles
var interacts: Array = []      # {"pos": Vector3, "label": String, "action": String, "npc": Dictionary}
var waypoints: Array = []      # Vector3 points on streets for wandering NPCs
var spots: Array = []          # {"pos", "rot", "stance", "loop"} places where someone stands or works
var lights: Array = []         # Vector3 positions for night lanterns
var spawn := Vector3(0, 0, 30)
var bounds := 50.0
var ice := false
## 0 poor, 1 middling, 2 rich: from the settlement's prosperity. Poor places
## have empty stalls, gaps where houses fell, mud, debris and beggars; rich
## ones taller houses, more lanterns, stocked stalls, gardens and crowds.
var wealth := 1
## Ground height by position: zero except in terraced cities (Omashu).
var terraced := false
const OM_EDGES := [20.0, -2.0, -24.0]   # tier boundaries along z, south to north
const OM_STEP := 3.2                     # rise per tier
const OM_STAIR := 3.8                    # half-width of the central stairs
var _prop_cache := {}

static func build(parent: Node3D, p_sid: String) -> RefCounted:
	var L = load("res://scripts/town/town_layout.gd").new()
	L.root = parent
	L.sid = p_sid
	L._make()
	return L

func _make() -> void:
	var d: Dictionary = Data.settlements[sid]
	culture = d.culture
	kind = d.type
	ice = culture in ["north", "south"]
	rng.seed = hash(sid)
	var pr: float = GS.settlements.get(sid, {}).get("prosperity", 50.0)
	wealth = 0 if pr < 35.0 else (2 if pr > 68.0 else 1)
	if GS.settlements.get(sid, {}).get("looted_until", -1.0) > GS.hours:
		wealth = 0
	match kind:
		"town":
			match sid:
				"omashu": _omashu()
				"ba_sing_se": _ba_sing_se()
				_: _town()
		"castle": _castle()
		"village": _village()
		"temple": _temple()
		_: _village()
	_wealth_dressing()
	_backdrop()
	if sid == "caldera":
		_volcano_rim()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func height_at(x: float, z: float) -> float:
	if not terraced:
		return 0.0
	var h := 0.0
	var on_stairs := absf(x) < OM_STAIR
	for e in OM_EDGES:
		if on_stairs:
			h += OM_STEP * clampf((e + 3.0 - z) / 6.0, 0.0, 1.0)
		elif z < e:
			h += OM_STEP
	return h

func add(n: Node3D, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	pos.y += height_at(pos.x, pos.z)
	n.position = pos
	n.rotation.y = rot_y
	root.add_child(n)
	return n

func block(c: Vector3, w: float, d: float) -> void:
	obstacles.append({"c": Vector2(c.x, c.z), "h": Vector2(w * 0.5, d * 0.5)})

func circle(c: Vector3, r: float) -> void:
	obstacles.append({"c": Vector2(c.x, c.z), "r": r})

func free_at(p: Vector3, margin: float) -> bool:
	var q := Vector2(p.x, p.z)
	for o in obstacles:
		if o.has("r"):
			if q.distance_to(o.c) < o.r + margin:
				return false
		elif absf(q.x - o.c.x) < o.h.x + margin and absf(q.y - o.c.y) < o.h.y + margin:
			return false
	return true

## A CC0 prop (Fantasy Props MegaKit) with model materials.
func prop(name: String, pos: Vector3, rot_y: float = 0.0, scale: float = 1.0, collide: float = 0.0) -> Node3D:
	var ps: PackedScene = _prop_cache.get(name)
	if ps == null:
		var path := "res://assets/props/%s.gltf" % name
		if not ResourceLoader.exists(path):
			path = "res://assets/nature/%s.gltf" % name
		ps = load(path)
		_prop_cache[name] = ps
	var n: Node3D = ps.instantiate()
	_apply_model_materials(n)
	n.scale = Vector3.ONE * scale
	add(n, pos, rot_y)
	if collide > 0.0:
		circle(pos, collide)
	return n

func _apply_model_materials(n: Node) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		for s in mi.mesh.get_surface_count():
			mi.set_surface_override_material(s, CB.model_material(mi.mesh.surface_get_material(s), {"saturation": 1.15}))
	for c in n.get_children():
		_apply_model_materials(c)

## Paved ground laid in individual stones, each a slightly different shade,
## with mortar showing between them.
func ground_patch(c: Vector3, w: float, d: float, col: Color, y: float = 0.03) -> void:
	var b = Arch.Builder.new()
	b.box(Vector3(0, -0.05 + y, 0), Vector3(w, 0.1, d), col * 0.72)
	var tile := 1.4 if not ice else 2.0
	var nx := maxi(1, int(w / tile))
	var nz := maxi(1, int(d / tile))
	var tw := w / nx
	var td := d / nz
	for i in nx:
		for k in nz:
			var off := (tw * 0.5) if (k % 2 == 1 and not ice) else 0.0
			var x := -w * 0.5 + (i + 0.5) * tw + off
			if x > w * 0.5 - tw * 0.4:
				continue
			var shade := rng.randf_range(0.9, 1.08)
			b.box(Vector3(x, y + 0.01, -d * 0.5 + (k + 0.5) * td), Vector3(tw - 0.09, 0.04, td - 0.09), col * shade)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = Arch.material(false)
	add(mi, c)

func paving() -> Color:
	var c := Color(0.66, 0.62, 0.54)
	if ice:
		c = Color(0.78, 0.86, 0.95)
	else:
		match culture:
			"fire": c = Color(0.36, 0.32, 0.31)
			"air": c = Color(0.82, 0.8, 0.74)
			"swamp": c = Color(0.35, 0.3, 0.2)
	# poor streets are trodden mud over broken paving; rich ones are swept
	if wealth == 0 and not ice:
		c = c.lerp(Color(0.36, 0.3, 0.22), 0.45)
	elif wealth == 2:
		c = c.lightened(0.06)
	return c

func tree(pos: Vector3) -> void:
	var names: Array
	match Data.settlements[sid].culture:
		"north", "south": names = ["Pine_1", "Pine_3", "Pine_5"]
		"fire": names = ["CommonTree_2", "CommonTree_5", "TwistedTree_3"] if Vector2(pos.x, pos.z).length() > bounds else ["CommonTree_2", "CommonTree_5"]
		"swamp": names = ["TwistedTree_2", "TwistedTree_4", "DeadTree_2"]
		"air": names = ["Pine_2", "Pine_4", "CommonTree_1"]
		_: names = ["CommonTree_1", "CommonTree_3", "CommonTree_4", "Pine_2"]
	if not free_at(pos, 1.0):
		return
	# never in the middle of the main street or the village path
	if absf(pos.x) < (6.0 if kind == "town" else 3.5) and pos.z > -30.0:
		return
	var inside := Vector2(pos.x, pos.z).length() < bounds
	if ice and inside:
		return   # nothing grows inside a city of ice
	# trees inside a settlement are tended garden trees, smaller than wild ones
	var sc := rng.randf_range(0.55, 0.85) if inside else rng.randf_range(0.9, 1.3)
	prop(names[rng.randi() % names.size()], pos, rng.randf() * TAU, sc, 0.6 * sc)

func street_lantern(pos: Vector3, rot: float) -> void:
	var col := Color(0.95, 0.25, 0.15) if culture in ["fire", "earth", "omashu", "hamakaze"] else Color(0.95, 0.85, 0.5)
	if culture == "air":
		col = Color(0.98, 0.65, 0.2)
	if ice:
		col = Color(0.55, 0.75, 1.0)
	add(Arch.lantern(col), pos, rot)
	circle(pos, 0.25)
	lights.append(pos + Vector3(0, 2.3 + height_at(pos.x, pos.z), 0))

func npc_spot(pos: Vector3, rot: float, stance: String = "", loop: String = "", role: Dictionary = {}) -> void:
	pos.y = height_at(pos.x, pos.z)
	spots.append({"pos": pos, "rot": rot, "stance": stance, "loop": loop, "role": role})

func interact(pos: Vector3, label: String, action: String, role_look: String = "", rot: float = 0.0, stance: String = "talk") -> void:
	var r := {"label": label, "action": action, "look": role_look}
	pos.y = height_at(pos.x, pos.z)
	interacts.append({"pos": pos, "label": label, "action": action})
	npc_spot(pos, rot, stance, "", r)

## A building whose footprint blocks movement. Returns its door position.
func building(pos: Vector3, w: float, d: float, floors: int, rot_y: float, opts: Dictionary = {}) -> Vector3:
	var n: Node3D
	if ice:
		var r := minf(w, d) * 0.55
		n = Arch.ice_dome(r, rot_y)
		circle(pos, r + 0.2)
	elif culture == "swamp":
		n = Arch.stilt_hut(w, d, rot_y)
		block(pos, (w if absf(sin(rot_y)) < 0.5 else d) + 0.4, (d if absf(sin(rot_y)) < 0.5 else w) + 0.4)
	else:
		n = Arch.hall(culture, w, d, floors, rot_y, opts)
		_weather(n)
		var ww := (w if absf(sin(rot_y)) < 0.5 else d) + 1.0
		var dd := (d if absf(sin(rot_y)) < 0.5 else w) + 1.0
		block(pos, ww, dd)
	add(n, pos)
	var fwd := Basis(Vector3.UP, rot_y) * Vector3(0, 0, 1)
	var depth := (minf(w, d) * 0.55 if ice else d * 0.5)
	if ice:
		depth = minf(w, d) * 0.55 * 1.3
	return pos + fwd * (depth + 1.3)

# ---------------------------------------------------------------------------
# Plans
# ---------------------------------------------------------------------------
func _walls(half: float, gate_gap: float) -> void:
	var wall_h := 6.5 if kind == "town" else 5.0
	if sid in ["ba_sing_se", "omashu", "caldera", "agna_qela"]:
		wall_h = 8.5
	var seg := 14.0
	# north, east, west
	for side in [[Vector3(0, 0, -half), 0.0], [Vector3(half, 0, 0), PI * 0.5], [Vector3(-half, 0, 0), PI * 0.5]]:
		var c: Vector3 = side[0]
		var rot: float = side[1]
		var n := int(ceil(half * 2.0 / seg))
		for i in n:
			var off := -half + (i + 0.5) * half * 2.0 / n
			var p := c + (Vector3(off, 0, 0) if rot == 0.0 else Vector3(0, 0, off))
			add(Arch.wall(culture, half * 2.0 / n + 0.05, wall_h, rot), p)
		block(c, (half * 2.0 + 2.0) if rot == 0.0 else 2.0, 2.0 if rot == 0.0 else (half * 2.0 + 2.0))
	# south, with the gate
	var left_len := half - gate_gap * 0.5 - 3.0
	for sgn in [-1.0, 1.0]:
		var cx: float = sgn * (gate_gap * 0.5 + 3.0 + left_len * 0.5)
		add(Arch.wall(culture, left_len, wall_h, 0.0), Vector3(cx, 0, half))
		block(Vector3(cx, 0, half), left_len, 2.0)
	add(Arch.gate(culture, wall_h), Vector3(0, 0, half))
	for x in [-3.6, 3.6]:
		block(Vector3(x, 0, half), 3.2, 3.2)

func _town() -> void:
	var half := 46.0
	bounds = half - 2.0
	var capital: bool = sid in ["ba_sing_se", "caldera", "omashu", "agna_qela", "southern_tribe"]
	_walls(half, 4.0)
	spawn = Vector3(0, 0, half - 5.0)
	# street and plaza
	ground_patch(Vector3(0, 0, 9), 8.0, half * 2.0 - 18.0, paving() * 0.95)
	ground_patch(Vector3(0, 0, 0), 28.0, 28.0, paving())
	for z in range(int(half - 8), -24, -9):
		street_lantern(Vector3(-4.6, 0, z), 0.0)
		street_lantern(Vector3(4.6, 0, z + 4.5), PI)
	for z in range(int(half - 6), -26, -6):
		waypoints.append(Vector3(rng.randf_range(-2.5, 2.5), 0, z))
	for i in 10:
		var a := TAU * i / 10.0
		waypoints.append(Vector3(cos(a) * 9.0, 0, sin(a) * 9.0))
	# palace / lord's hall
	var palace_door := building(Vector3(0, 0, -32), 18.0 if capital else 14.0, 10.0, 3 if capital else 2, 0.0, {"floor_h": 3.2})
	interact(palace_door + Vector3(1.6, 0, 0.4), "Speak with the steward of the hall", "hall", "steward", PI)
	npc_spot(palace_door + Vector3(-2.2, 0, 0.0), 0.0, "folded", "", {"look": "guard"})
	npc_spot(palace_door + Vector3(3.8, 0, 0.0), 0.0, "folded", "", {"look": "guard"})
	# market
	var stall_spots := [Vector3(-10, 0, -8), Vector3(-10, 0, 0), Vector3(-10, 0, 8), Vector3(10, 0, -8), Vector3(10, 0, 8)]
	for i in stall_spots.size():
		var sp: Vector3 = stall_spots[i]
		var rot := PI * 0.5 if sp.x < 0 else -PI * 0.5
		if wealth == 0 and i % 2 == 1:
			continue   # stalls given up
		prop("Stall_Empty" if i % 2 == 0 else "Stall_Cart_Empty", sp, rot, 1.0, 1.4)
		var goods := ["FarmCrate_Apple", "FarmCrate_Carrot", "Barrel_Apples", "Vase_2", "Pot_1"]
		for k in [0, 1, 2][wealth]:
			prop(goods[(i + k) % goods.size()], sp + Vector3(signf(-sp.x) * 1.3, 0, 1.1 - k * 1.1), rng.randf() * TAU, 0.8, 0.4)
	interact(Vector3(-8.2, 0, 0), "Browse the market", "trade", "merchant", PI * 0.5, "talk")
	npc_spot(Vector3(-8.2, 0, -8), PI * 0.5, "talk")
	npc_spot(Vector3(8.2, 0, 8), -PI * 0.5, "talk")
	# smithy
	prop("Anvil", Vector3(10.5, 0, 0), 0.0, 1.0, 0.6)
	prop("WeaponStand", Vector3(12.0, 0, -1.6), -PI * 0.5, 1.0, 0.6)
	prop("Barrel", Vector3(12.2, 0, 1.6), 0.0, 1.0, 0.5)
	interact(Vector3(9.0, 0, 0.3), "Visit the weaponsmith", "shop", "smith", -PI * 0.5, "work")
	# tavern and guild hall flank the street
	var tav_door := building(Vector3(-15, 0, 18), 10.0, 8.0, 2, PI * 0.5)
	interact(tav_door + Vector3(0, 0, 1.6), "Enter the tavern", "tavern", "innkeeper", -PI * 0.5)
	for k in 2:
		add(Arch.lantern(Color(0.95, 0.3, 0.15)), tav_door + Vector3(0.2, 0, -1.8 + k * 3.6), PI)
		lights.append(tav_door + Vector3(0.6, 2.3, -1.8 + k * 3.6))
	prop("Bench", tav_door + Vector3(1.2, 0, -3.2), 0.0, 1.0, 0.6)
	npc_spot(tav_door + Vector3(1.2, 0, -3.2), PI * 0.5, "sit")
	var guild_door := building(Vector3(15, 0, 18), 10.0, 8.0, 1, -PI * 0.5)
	interact(guild_door, "Ask the guild master for work", "work", "guildmaster", PI * 0.5)
	if sid == "gaoling":
		interact(Vector3(0, 0, -14), "Visit the Stone Pit", "arena", "promoter", 0.0)
	if sid == "southern_tribe":
		interact(Vector3(-6, 0, -16), "Go to the council hall", "council", "elder", 0.0)
	if sid == "ba_sing_se":
		interact(Vector3(6, 0, -18), "Approach the ring gates", "main", "guard", 0.0, "folded")
	# houses on the remaining blocks
	for gx in range(-38, 39, 11):
		for gz in range(-40, 41, 11):
			var p := Vector3(gx + rng.randf_range(-1.5, 1.5), 0, gz + rng.randf_range(-1.5, 1.5))
			if absf(p.x) < 10.0 and p.z > -26.0:
				continue
			if absf(p.x) < 18.0 and absf(p.z) < 18.0:
				continue
			if absf(p.z - 18.0) < 8.0 and absf(absf(p.x) - 15.0) < 8.0:
				continue
			if absf(p.x) > half - 7.0 or absf(p.z) > half - 7.0:
				continue
			if not free_at(p, 3.5):
				continue
			var w := rng.randf_range(6.0, 8.5)
			var dd := rng.randf_range(5.0, 6.5)
			var face := -PI * 0.5 if p.x > 0 else PI * 0.5
			if absf(p.x) > 24.0:
				face = 0.0
			if wealth == 0 and rng.randf() < 0.3:
				_ruin(p, w, dd)
				continue
			var tall: float = [0.08, 0.25, 0.55][wealth]
			building(p, w, dd, (3 if wealth == 2 and rng.randf() < 0.2 else 2) if rng.randf() < tall else 1, face)
	for i in 18:
		tree(Vector3(rng.randf_range(-half + 5, half - 5), 0, rng.randf_range(-half + 5, half - 5)))
	# a few people about
	for i in 6:
		var sp2: Vector3 = waypoints[rng.randi() % waypoints.size()]
		npc_spot(sp2 + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)), rng.randf() * TAU, "talk")
	# gate guards
	npc_spot(Vector3(-2.6, 0, half - 3.0), PI, "folded", "", {"look": "guard"})
	npc_spot(Vector3(2.6, 0, half - 3.0), PI, "folded", "", {"look": "guard"})
	interact(Vector3(-4.0, 0, half - 6.0), "Talk to the gatekeeper (settlement menu)", "main", "guard", PI * 0.5, "folded")

## Omashu: a city cut into a mountain in four terraces, joined by a central
## stair, with the Courier Guild's delivery chutes running down the flanks.
## Tiers rise to the north; the palace crowns the top.
func _omashu() -> void:
	terraced = true
	var half := 46.0
	bounds = half - 2.0
	var stone := Color(0.48, 0.45, 0.4)
	var lows := [20.0, -2.0, -24.0, -46.0]
	var highs := [46.0, 20.0, -2.0, -24.0]
	# terrace slabs and their retaining faces
	var b = Arch.Builder.new()
	for i in 4:
		var top: float = OM_STEP * i
		var zc: float = (lows[i] + highs[i]) * 0.5
		b.box(Vector3(0, (top - 0.6) * 0.5, zc), Vector3(half * 2.0, top + 0.6, highs[i] - lows[i] - 0.2), stone * (0.9 + 0.04 * i))
		# lawn over the terrace top, kept back from the retaining face
		b.box(Vector3(0, top - 0.04, zc), Vector3(half * 2.0 - 1.0, 0.1, highs[i] - lows[i] - 1.4), Color(0.42, 0.56, 0.3) * (0.95 + 0.03 * i))
	# the central stairs between tiers, with a parapet along each terrace lip
	for i in OM_EDGES.size():
		var e: float = OM_EDGES[i]
		var base: float = OM_STEP * i
		for j in 8:
			var top2: float = base + OM_STEP * (j + 1) / 8.0
			b.box(Vector3(0, (top2 - 0.6) * 0.5, e + 3.0 - (j + 0.5) * 0.75), Vector3(OM_STAIR * 2.0, top2 + 0.6, 0.78), stone * 1.08)
		for sgn in [-1.0, 1.0]:
			var pl: float = (half - OM_STAIR) * 0.5
			b.box(Vector3(sgn * (OM_STAIR + pl), base + OM_STEP + 0.4, e - 0.5), Vector3(half - OM_STAIR, 0.8, 1.0), stone * 0.82)
			b.box(Vector3(sgn * (OM_STAIR + 0.1), base + OM_STEP * 0.5 + 0.5, e), Vector3(0.3, OM_STEP + 0.9, 6.4), stone * 0.8, 0.0)
			block(Vector3(sgn * (OM_STAIR + pl), 0, e), half - OM_STAIR, 2.0)
	# stonework: courses of blocks on every retaining face, and lanterns along the parapet
	var srng := RandomNumberGenerator.new()
	srng.seed = 77
	for i in OM_EDGES.size():
		var e: float = OM_EDGES[i]
		var base: float = OM_STEP * i
		for sgn in [-1.0, 1.0]:
			for c in 6:
				var cy: float = base + 0.3 + c * (OM_STEP + 0.2) / 6.0
				var x := OM_STAIR + 0.4 + (0.9 if c % 2 == 1 else 0.0)
				while x < half - 0.5:
					var bw: float = srng.randf_range(1.5, 2.4)
					b.box(Vector3(sgn * (x + bw * 0.5), cy, e + 0.02), Vector3(bw - 0.08, (OM_STEP + 0.2) / 6.0 - 0.07, 0.22), stone * srng.randf_range(0.82, 1.16))
					x += bw
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = Arch.material(false)
	root.add_child(mi)
	for i in OM_EDGES.size():
		var e2: float = OM_EDGES[i]
		for lx in [-36.0, -26.0, -16.0, -8.0, 8.0, 16.0, 26.0, 36.0]:
			var lp := Vector3(lx, OM_STEP * i + OM_STEP + 0.8, e2 - 0.5)
			root.add_child(_lantern_at(lp))
			lights.append(lp + Vector3(0, 2.3, 0))
	# walls: each tier's stretch at its own height, the gate in the south
	for i in 4:
		var len: float = highs[i] - lows[i]
		var zc2: float = (lows[i] + highs[i]) * 0.5
		for sgn in [-1.0, 1.0]:
			add(Arch.wall("omashu", len, 8.5, PI * 0.5), Vector3(sgn * half, 0, zc2))
			block(Vector3(sgn * half, 0, zc2), 2.0, len)
	for k in 7:
		var cx: float = -half + (k + 0.5) * half * 2.0 / 7.0
		add(Arch.wall("omashu", half * 2.0 / 7.0 + 0.05, 8.5, 0.0), Vector3(cx, 0, -half))
	block(Vector3(0, 0, -half), half * 2.0 + 2.0, 2.0)
	var gate_gap := 4.0
	var left_len := half - gate_gap * 0.5 - 3.0
	for sgn in [-1.0, 1.0]:
		var gx: float = sgn * (gate_gap * 0.5 + 3.0 + left_len * 0.5)
		add(Arch.wall("omashu", left_len, 8.5, 0.0), Vector3(gx, 0, half))
		block(Vector3(gx, 0, half), left_len, 2.0)
	add(Arch.gate("omashu", 8.5), Vector3(0, 0, half))
	for x in [-3.6, 3.6]:
		block(Vector3(x, 0, half), 3.2, 3.2)
	spawn = Vector3(0, 0, half - 5.0)
	# the main street, tier by tier, and the plazas
	ground_patch(Vector3(0, 0, 33), 8.0, 24.0, paving() * 0.95)
	ground_patch(Vector3(0, 0, 33), 24.0, 14.0, paving())
	ground_patch(Vector3(0, 0, 9), 8.0, 16.0, paving() * 0.95)
	ground_patch(Vector3(0, 0, 9), 22.0, 12.0, paving())
	ground_patch(Vector3(0, 0, -13), 8.0, 16.0, paving() * 0.95)
	ground_patch(Vector3(0, 0, -35), 30.0, 16.0, paving())
	for z in [40.0, 30.0, 14.0, 4.0, -8.0, -18.0, -30.0]:
		street_lantern(Vector3(-4.8, 0, z), 0.0)
		street_lantern(Vector3(4.8, 0, z + 2.0), PI)
	for z in range(40, -36, -6):
		waypoints.append(Vector3(rng.randf_range(-2.0, 2.0), 0, z))
	# the palace on the summit
	var palace_door := building(Vector3(0, 0, -36), 20.0, 10.0, 3, 0.0, {"floor_h": 3.2})
	interact(palace_door + Vector3(1.6, 0, 0.4), "Speak with the steward of the hall", "hall", "steward", PI)
	npc_spot(palace_door + Vector3(-2.2, 0, 0.0), 0.0, "folded", "", {"look": "guard"})
	npc_spot(palace_door + Vector3(3.8, 0, 0.0), 0.0, "folded", "", {"look": "guard"})
	# market below, on the lowest tier
	var stalls := [Vector3(-9, 0, 28), Vector3(-9, 0, 37), Vector3(9, 0, 28), Vector3(9, 0, 37)]
	for i in stalls.size():
		var sp: Vector3 = stalls[i]
		if wealth == 0 and i % 2 == 1:
			continue
		prop("Stall_Empty" if i % 2 == 0 else "Stall_Cart_Empty", sp, PI * 0.5 if sp.x < 0 else -PI * 0.5, 1.0, 1.4)
		var goods := ["FarmCrate_Apple", "FarmCrate_Carrot", "Barrel_Apples", "Vase_2", "Pot_1"]
		for k in [0, 1, 2][wealth]:
			prop(goods[(i + k) % goods.size()], sp + Vector3(signf(-sp.x) * 1.3, 0, 1.1 - k * 1.1), rng.randf() * TAU, 0.8, 0.4)
	interact(Vector3(-7.2, 0, 28), "Browse the market", "trade", "merchant", PI * 0.5, "talk")
	npc_spot(Vector3(7.2, 0, 37), -PI * 0.5, "talk")
	# smithy on the second tier, tavern and guild by the gate
	prop("Anvil", Vector3(10.5, 0, 9), 0.0, 1.0, 0.6)
	prop("WeaponStand", Vector3(12.0, 0, 7.4), -PI * 0.5, 1.0, 0.6)
	prop("Barrel", Vector3(12.2, 0, 10.6), 0.0, 1.0, 0.5)
	interact(Vector3(9.0, 0, 9.3), "Visit the weaponsmith", "shop", "smith", -PI * 0.5, "work")
	var tav_door := building(Vector3(-19, 0, 33), 10.0, 8.0, 2, PI * 0.5)
	interact(tav_door + Vector3(0, 0, 1.6), "Enter the tavern", "tavern", "innkeeper", -PI * 0.5)
	for k in 2:
		add(Arch.lantern(Color(0.95, 0.3, 0.15)), tav_door + Vector3(0.2, 0, -1.8 + k * 3.6), PI)
		lights.append(tav_door + Vector3(0.6, 2.3, -1.8 + k * 3.6))
	var guild_door := building(Vector3(19, 0, 33), 10.0, 8.0, 1, -PI * 0.5)
	interact(guild_door, "Ask the guild master for work", "work", "guildmaster", PI * 0.5)
	# houses climb the flanks, tier by tier, facing the street
	for i in 4:
		var z0: float = lows[i] + 8.0
		var z1: float = highs[i] - 8.0
		var gz := z0
		while gz <= z1:
			for sgn in [-1.0, 1.0]:
				for gx2 in [12.0, 20.0, 28.0, 37.0]:
					var p := Vector3(sgn * (gx2 + rng.randf_range(-1.2, 1.2)), 0, gz + rng.randf_range(-1.0, 1.0))
					if absf(p.z - 33.0) < 8.0 and i == 0 or (absf(p.x) < 9.0):
						continue
					if i == 3 and absf(p.x) < 14.0:
						continue
					if not free_at(p, 3.2):
						continue
					var w := rng.randf_range(6.0, 8.5)
					var dd := rng.randf_range(5.0, 6.5)
					if wealth == 0 and rng.randf() < 0.3:
						_ruin(p, w, dd)
						continue
					var tall: float = [0.15, 0.35, 0.6][wealth]
					building(p, w, dd, 2 if rng.randf() < tall else 1, -PI * 0.5 * sgn if gx2 < 30.0 else (PI if rng.randf() < 0.5 else 0.0))
			gz += 11.0
	for i in 8:
		tree(Vector3(rng.randf_range(-40, 40), 0, rng.randf_range(-20, 40)))
	for i in 6:
		var sp2: Vector3 = waypoints[rng.randi() % waypoints.size()]
		npc_spot(sp2 + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)), rng.randf() * TAU, "talk")
	npc_spot(Vector3(-2.6, 0, half - 3.0), PI, "folded", "", {"look": "guard"})
	npc_spot(Vector3(2.6, 0, half - 3.0), PI, "folded", "", {"look": "guard"})
	interact(Vector3(-4.0, 0, half - 6.0), "Talk to the gatekeeper (settlement menu)", "main", "guard", PI * 0.5, "folded")
	_chutes(half)
	_mountain()

## The Courier Guild's delivery chutes: open stone troughs on pillars that run
## from the palace down both flanks to the gate.
func _lantern_at(p: Vector3) -> Node3D:
	var n: Node3D = Arch.lantern(Color(0.95, 0.25, 0.15))
	n.position = p
	return n

func _chutes(half: float) -> void:
	var col := Color(0.5, 0.46, 0.4)
	var pb = Arch.Builder.new()
	var tb = Arch.Builder.new()
	var top_y := 12.4
	var bot_y := 2.6
	for sgn in [-1.0, 1.0]:
		var pts: Array = []
		for k in 5:
			var t: float = k / 4.0
			pts.append(Vector3(sgn * (half - 5.0 + (3.0 if k % 2 == 1 else 0.0)), lerpf(top_y, bot_y, t), lerpf(-36.0, 42.0, t)))
		for k in pts.size():
			var pp: Vector3 = pts[k]
			pb.box(Vector3(pp.x, (pp.y - 0.4) * 0.5 - 0.1, pp.z), Vector3(0.9, pp.y - 0.4 + 0.2, 0.9), col * 0.85)
			if k > 0:
				var a: Vector3 = pts[k - 1]
				var len := a.distance_to(pp)
				var xf := Transform3D(Basis.looking_at(pp - a, Vector3.UP), (a + pp) * 0.5)
				# trough in its own space, along Z
				var tr = Arch.Builder.new()
				tr.box(Vector3(0, 0, 0), Vector3(1.8, 0.22, len), col)
				tr.box(Vector3(-0.85, 0.3, 0), Vector3(0.18, 0.55, len), col * 1.08)
				tr.box(Vector3(0.85, 0.3, 0), Vector3(0.18, 0.55, len), col * 1.08)
				var tmi := MeshInstance3D.new()
				tmi.mesh = tr.commit()
				tmi.material_override = Arch.material(false)
				tmi.transform = xf
				root.add_child(tmi)
	var pmi := MeshInstance3D.new()
	pmi.mesh = pb.commit()
	pmi.material_override = Arch.material(false)
	root.add_child(pmi)

## The mountain the city is cut into, rising behind the palace.
func _mountain() -> void:
	var b = Arch.Builder.new()
	for i in 9:
		var x: float = -80.0 + i * 20.0 + rng.randf_range(-4, 4)
		var h := rng.randf_range(48.0, 80.0) - absf(x) * 0.25
		b.cyl(Vector3(x, -2.0, -78.0 + rng.randf_range(-6, 6)), rng.randf_range(26.0, 36.0), rng.randf_range(3.0, 9.0), h, Color(0.55, 0.53, 0.5) * rng.randf_range(0.85, 1.05), 7)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	var m: ShaderMaterial = Arch.material(false).duplicate()
	m.set_shader_parameter("brush_scale", 0.05)
	m.set_shader_parameter("brush_strength", 0.15)
	mi.material_override = m
	root.add_child(mi)

## Ba Sing Se: three walled rings, one inside the next, each gate opening onto
## the same avenue. The outer ring is crowded with refugees and tenements, the
## middle ring is shops, market and guilds, the inner ring is the palace and
## its gardens.
func _ba_sing_se() -> void:
	var half := 46.0
	bounds = half - 2.0
	_walls(half, 4.0)
	_walls(30.0, 4.0)
	_walls(16.0, 4.0)
	spawn = Vector3(0, 0, half - 5.0)
	# the avenue, gate to gate, and a plaza before each inner gate
	ground_patch(Vector3(0, 0, 21), 8.0, 50.0, paving() * 0.95)
	ground_patch(Vector3(0, 0, 0), 8.0, 20.0, paving() * 0.95)
	ground_patch(Vector3(0, 0, 24), 22.0, 12.0, paving())
	ground_patch(Vector3(0, 0, 38), 14.0, 10.0, paving() * 0.92)
	ground_patch(Vector3(0, 0, -4), 26.0, 18.0, paving().lightened(0.08))
	for z in [41.0, 33.0, 25.0, 19.0, 11.0, 3.0, -5.0]:
		street_lantern(Vector3(-4.8, 0, z), 0.0)
		street_lantern(Vector3(4.8, 0, z + 2.0), PI)
	for z in range(42, -4, -6):
		waypoints.append(Vector3(rng.randf_range(-2.0, 2.0), 0, z))
	# the palace and its guards
	var palace_door := building(Vector3(0, 0, -7), 20.0, 10.0, 3, 0.0, {"floor_h": 3.2})
	interact(palace_door + Vector3(1.6, 0, 0.4), "Speak with the steward of the hall", "hall", "steward", PI)
	npc_spot(palace_door + Vector3(-2.2, 0, 0.0), 0.0, "folded", "", {"look": "guard"})
	npc_spot(palace_door + Vector3(3.8, 0, 0.0), 0.0, "folded", "", {"look": "guard"})
	interact(Vector3(6, 0, 5), "Approach the ring gates", "main", "guard", 0.0, "folded")
	# gate guards at each of the three gates
	for gz in [half, 30.0, 16.0]:
		npc_spot(Vector3(-2.6, 0, gz - 3.0), PI, "folded", "", {"look": "guard"})
		npc_spot(Vector3(2.6, 0, gz - 3.0), PI, "folded", "", {"look": "guard"})
	interact(Vector3(-4.0, 0, half - 6.0), "Talk to the gatekeeper (settlement menu)", "main", "guard", PI * 0.5, "folded")
	# middle ring: market, tavern, guild and smithy
	var stalls := [Vector3(-10, 0, 22), Vector3(-10, 0, 27), Vector3(10, 0, 22), Vector3(10, 0, 27)]
	for i in stalls.size():
		var sp: Vector3 = stalls[i]
		if wealth == 0 and i % 2 == 1:
			continue
		prop("Stall_Empty" if i % 2 == 0 else "Stall_Cart_Empty", sp, PI * 0.5 if sp.x < 0 else -PI * 0.5, 1.0, 1.4)
		var goods := ["FarmCrate_Apple", "FarmCrate_Carrot", "Barrel_Apples", "Vase_2", "Pot_1"]
		for k in [0, 1, 2][wealth]:
			prop(goods[(i + k) % goods.size()], sp + Vector3(signf(-sp.x) * 1.3, 0, 1.1 - k * 1.1), rng.randf() * TAU, 0.8, 0.4)
	interact(Vector3(-8.2, 0, 22), "Browse the market", "trade", "merchant", PI * 0.5, "talk")
	npc_spot(Vector3(8.2, 0, 27), -PI * 0.5, "talk")
	prop("Anvil", Vector3(24.5, 0, -4), 0.0, 1.0, 0.6)
	prop("WeaponStand", Vector3(26.0, 0, -5.6), -PI * 0.5, 1.0, 0.6)
	interact(Vector3(23.0, 0, -3.7), "Visit the weaponsmith", "shop", "smith", -PI * 0.5, "work")
	var tav_door := building(Vector3(-22, 0, 22), 10.0, 8.0, 2, PI * 0.5)
	interact(tav_door + Vector3(0, 0, 1.6), "Enter the tavern", "tavern", "innkeeper", -PI * 0.5)
	for k in 2:
		add(Arch.lantern(Color(0.95, 0.3, 0.15)), tav_door + Vector3(0.2, 0, -1.8 + k * 3.6), PI)
		lights.append(tav_door + Vector3(0.6, 2.3, -1.8 + k * 3.6))
	var guild_door := building(Vector3(22, 0, 22), 10.0, 8.0, 1, -PI * 0.5)
	interact(guild_door, "Ask the guild master for work", "work", "guildmaster", PI * 0.5)
	# houses: tenements crowd the outer ring, tidy rows the middle, gardens inside
	for gx in range(-42, 43, 8):
		for gz in range(-42, 43, 8):
			var m := maxf(absf(gx), absf(gz))
			var ring := 0 if m > 32.0 else (1 if m > 18.0 else 2)
			if ring == 2:
				continue
			var p := Vector3(gx + rng.randf_range(-1.0, 1.0), 0, gz + rng.randf_range(-1.0, 1.0))
			if absf(p.x) < 6.5 and p.z > -8.0:
				continue
			var pm := maxf(absf(p.x), absf(p.z))
			if (ring == 0 and (pm < 33.5 or pm > 42.5)) or (ring == 1 and (pm < 19.5 or pm > 27.0)):
				continue
			if not free_at(p, 3.2):
				continue
			var w := rng.randf_range(5.5, 8.0) if ring == 0 else rng.randf_range(6.5, 8.5)
			var dd := rng.randf_range(4.5, 6.0)
			var face := (-PI * 0.5 if p.x > 0 else PI * 0.5) if absf(p.x) > absf(p.z) else (PI if p.z < 0 else 0.0)
			if (wealth == 0 or ring == 0) and rng.randf() < (0.3 if wealth == 0 else 0.1):
				_ruin(p, w, dd)
				continue
			var tall: float = [0.05, 0.2, 0.45][wealth] + (0.15 if ring == 1 else 0.0)
			building(p, w, dd, 2 if rng.randf() < tall else 1, face)
	# gardens in the inner ring
	for i in 12:
		tree(Vector3(rng.randf_range(-13, 13), 0, rng.randf_range(-13, 13)))
	for i in 8:
		var sp2: Vector3 = waypoints[rng.randi() % waypoints.size()]
		npc_spot(sp2 + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)), rng.randf() * TAU, "talk")

## Caldera: the capital sits in the crater of a volcano; a ring of dark cones
## rises around it.
func _volcano_rim() -> void:
	var b = Arch.Builder.new()
	for i in 20:
		var a := TAU * i / 20.0 + rng.randf_range(-0.08, 0.08)
		var r := rng.randf_range(78.0, 92.0)
		var h := rng.randf_range(26.0, 46.0)
		var c := Vector3(cos(a) * r, -2.0, sin(a) * r)
		b.cyl(c, rng.randf_range(20.0, 28.0), rng.randf_range(4.0, 9.0), h, Color(0.26, 0.22, 0.21) * rng.randf_range(0.8, 1.1), 7)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	var m: ShaderMaterial = Arch.material(false).duplicate()
	m.set_shader_parameter("brush_scale", 0.05)
	m.set_shader_parameter("brush_strength", 0.15)
	mi.material_override = m
	add(mi, Vector3.ZERO)

func _castle() -> void:
	var half := 30.0
	bounds = half - 2.0
	_walls(half, 4.0)
	spawn = Vector3(0, 0, half - 5.0)
	ground_patch(Vector3(0, 0, 0), half * 2.0 - 4.0, half * 2.0 - 4.0, paving() * 0.9)
	var keep_door := building(Vector3(0, 0, -14), 14.0, 10.0, 3, 0.0, {"floor_h": 3.4})
	interact(keep_door + Vector3(1.6, 0, 0.3), "Speak with the castle steward", "hall", "steward", PI)
	npc_spot(keep_door + Vector3(-2.0, 0, 0.0), 0.0, "folded", "", {"look": "guard"})
	building(Vector3(-19, 0, 4), 12.0, 7.0, 1, PI * 0.5)
	building(Vector3(19, 0, 4), 12.0, 7.0, 1, -PI * 0.5)
	# training yard
	for i in 4:
		var p := Vector3(-6 + i * 4.0, 0, 6)
		prop("Dummy", p, PI, 1.0, 0.5)
		npc_spot(p + Vector3(0, 0, 1.6), PI, "", "ual2/Sword_Regular_A", {"look": "soldier"})
	prop("WeaponStand", Vector3(-9, 0, 2), 0.0, 1.0, 0.6)
	prop("WeaponStand", Vector3(9, 0, 2), 0.0, 1.0, 0.6)
	interact(Vector3(8, 0, 12), "Speak with the quartermaster (work)", "work", "quartermaster", -PI * 0.5)
	for i in 4:
		prop(["Crate_Wooden", "Barrel", "Chest_Wood", "Bag"][i], Vector3(10 + (i % 2) * 1.4, 0, 14 + int(i / 2) * 1.4), rng.randf() * TAU, 1.0, 0.6)
	for z in [-2.0, 10.0, 20.0]:
		street_lantern(Vector3(-4.5, 0, z), 0.0)
		street_lantern(Vector3(4.5, 0, z), PI)
	for z in range(int(half - 6), -6, -5):
		waypoints.append(Vector3(rng.randf_range(-3, 3), 0, z))
	npc_spot(Vector3(-2.6, 0, half - 3.0), PI, "folded", "", {"look": "guard"})
	npc_spot(Vector3(2.6, 0, half - 3.0), PI, "folded", "", {"look": "guard"})
	interact(Vector3(-4.0, 0, half - 6.0), "Talk to the gatekeeper (settlement menu)", "main", "guard", PI * 0.5, "folded")

func _village() -> void:
	bounds = 38.0
	spawn = Vector3(0, 0, 28)
	ground_patch(Vector3(0, 0, 0), 12.0, 12.0, paving() * 0.9)
	ground_patch(Vector3(0, 0, 16), 4.0, 22.0, paving() * 0.85)
	# well / central fire
	var b = Arch.Builder.new()
	if ice:
		b.cyl(Vector3.ZERO, 0.9, 0.8, 0.5, Color(0.7, 0.8, 0.92), 10)
		b.cyl(Vector3(0, 0.5, 0), 0.5, 0.0, 0.9, Color(1.0, 0.6, 0.25), 8)
	else:
		b.cyl(Vector3.ZERO, 1.1, 1.0, 0.8, Arch.style(culture).plinth, 12)
		b.cyl(Vector3(0, 0.8, 0), 0.9, 0.9, 0.05, Color(0.25, 0.4, 0.5), 12)
		for x in [-0.9, 0.9]:
			b.box(Vector3(x, 1.5, 0), Vector3(0.15, 1.4, 0.15), Arch.style(culture).timber)
		b.box(Vector3(0, 2.25, 0), Vector3(2.2, 0.15, 0.25), Arch.style(culture).timber)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = Arch.material()
	add(mi, Vector3.ZERO)
	circle(Vector3.ZERO, 1.3)
	interact(Vector3(2.2, 0, 1.2), "Speak with the village elder (work, volunteers)", "village", "elder", -PI * 0.6)
	# houses in a loose ring
	var n := 7 + rng.randi() % 3
	for i in n:
		var a := TAU * (i + 0.3) / n + rng.randf_range(-0.2, 0.2)
		var r := rng.randf_range(11.0, 17.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if p.z > 8.0 and absf(p.x) < 6.0:
			p.x += 9.0 * signf(p.x + 0.01)
		if not free_at(p, 3.0):
			continue
		var face := atan2(-p.x, -p.z)
		face = round(face / (PI * 0.5)) * PI * 0.5
		if wealth == 0 and not ice and rng.randf() < 0.3:
			_ruin(p, 6.0, 5.0)
			continue
		building(p, rng.randf_range(5.5, 7.0), rng.randf_range(4.5, 5.5), 1, face)
	# fields and work
	if ice:
		for i in 3:
			var rp := Vector3(-20 + i * 5.0, 0, -18)
			prop("Rope_1", rp, 0.0, 1.5, 0.0)
			npc_spot(rp + Vector3(0, 0, 1.5), PI, "", "ual2/Farm_Harvest")
	elif culture != "swamp":
		var water := culture in ["earth", "fire", "hamakaze", "omashu"]
		for i in 4:
			var fp := Vector3(-24.0 + i * 13.0, 0, -26.0 + (i % 2) * 4.0)
			add(Arch.paddy(10.0, 7.0, water), fp)
			block(fp, 10.6, 7.6)
			npc_spot(fp + Vector3(rng.randf_range(-3, 3), 0, 4.6), PI, "", "ual2/Farm_Harvest")
	interact(Vector3(-2.6, 0, 3.0), "Buy supplies from the villagers", "trade", "farmer", PI * 0.3)
	prop("FarmCrate_Carrot", Vector3(-3.6, 0, 3.6), 0.4, 1.0, 0.5)
	prop("Barrel_Apples", Vector3(-3.8, 0, 2.2), 0.0, 1.0, 0.5)
	for i in 8:
		var a2 := TAU * i / 8.0
		waypoints.append(Vector3(cos(a2) * 6.5, 0, sin(a2) * 6.5))
	waypoints.append(Vector3(0, 0, 20))
	street_lantern(Vector3(3.0, 0, 8.0), PI)
	street_lantern(Vector3(-3.0, 0, -6.0), 0.0)
	for i in 22:
		tree(Vector3(rng.randf_range(-36, 36), 0, rng.randf_range(-36, 36)))
	npc_spot(Vector3(-5, 0, -2), 0.8, "sit_talk")
	npc_spot(Vector3(5, 0, 5), -2.4, "talk")

func _temple() -> void:
	bounds = 40.0
	spawn = Vector3(0, 0, 30)
	ground_patch(Vector3(0, 0, -2), 44.0, 40.0, paving())
	ground_patch(Vector3(0, 0, 22), 6.0, 16.0, paving() * 0.95)
	var hall_door := building(Vector3(0, 0, -14), 16.0, 10.0, 3, 0.0, {"floor_h": 3.0, "curl": 0.45})
	interact(hall_door + Vector3(0, 0, 0.6), "Bow to the abbot (temple)", "main", "abbot", PI)
	for p in [Vector3(-16, 0, -16), Vector3(16, 0, -16), Vector3(-17, 0, 8), Vector3(17, 0, 8)]:
		add(Arch.air_tower(2.6, 9.0 + rng.randf_range(-1.0, 2.0)), p)
		circle(p, 3.2)
	# meditation terrace and gardens
	for i in 6:
		var mp := Vector3(-7.5 + i * 3.0, 0, 4.0)
		npc_spot(mp, PI, "sit", "", {"look": "monk"})
	interact(Vector3(-8, 0, 14), "Visit the temple stores", "trade", "monk", PI * 0.5)
	prop("Table_Large", Vector3(-10, 0, 14), PI * 0.5, 1.0, 1.0)
	prop("Barrel_Apples", Vector3(-10.5, 0, 16), 0.0, 1.0, 0.5)
	for i in 10:
		var a := TAU * i / 10.0
		waypoints.append(Vector3(cos(a) * 11.0, 0, sin(a) * 9.0 + 2.0))
	for x in [-3.5, 3.5]:
		for z in [12.0, 20.0, 28.0]:
			street_lantern(Vector3(x, 0, z), 0.0 if x < 0 else PI)
	for i in 14:
		tree(Vector3(rng.randf_range(-36, 36), 0, rng.randf_range(-36, 36)))
	for i in 3:
		var sp: Vector3 = waypoints[i * 3]
		npc_spot(sp, rng.randf() * TAU, "talk", "", {"look": "monk"})

## Hills and far mountains so the settlement sits in a landscape, not a void.
func _backdrop() -> void:
	var b = Arch.Builder.new()
	var biome: String = GS.sim.biome_at(Data.settlements[sid].pos)
	var mcol := Color(0.5, 0.56, 0.48)
	match biome:
		"snow": mcol = Color(0.86, 0.9, 0.97)
		"desert": mcol = Color(0.82, 0.68, 0.48)
		"volcanic": mcol = Color(0.36, 0.3, 0.3)
		"swamp": mcol = Color(0.3, 0.38, 0.26)
		"highland", "mountain": mcol = Color(0.55, 0.55, 0.52)
	for i in 22:
		var a := TAU * i / 22.0 + rng.randf_range(-0.1, 0.1)
		var r := rng.randf_range(120.0, 170.0)
		var h := rng.randf_range(25.0, 60.0)
		var c := Vector3(cos(a) * r, -2.0, sin(a) * r)
		b.cyl(c, rng.randf_range(30.0, 50.0), rng.randf_range(2.0, 8.0), h, mcol * rng.randf_range(0.85, 1.05), 7)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	var m: ShaderMaterial = Arch.material(false).duplicate()
	m.set_shader_parameter("brush_scale", 0.05)
	m.set_shader_parameter("brush_strength", 0.15)
	mi.material_override = m
	add(mi, Vector3.ZERO)
	# a ring of trees outside the walls
	for i in 40:
		var a2 := rng.randf() * TAU
		var r2 := rng.randf_range(bounds + 10.0, bounds + 40.0)
		tree(Vector3(cos(a2) * r2, 0, sin(a2) * r2))

## A fallen house: a low broken shell with rubble.
func _ruin(p: Vector3, w: float, d: float) -> void:
	var b = Arch.Builder.new()
	var st: Dictionary = Arch.style(culture)
	var wallc: Color = st.get("wall", Color(0.6, 0.55, 0.48)) * 0.75
	for side in 4:
		if rng.randf() < 0.35:
			continue
		var hgt := rng.randf_range(0.6, 2.0)
		var along := side % 2 == 0
		var off := Vector3(0, hgt * 0.5, (d * 0.5 if side == 0 else -d * 0.5)) if along else Vector3((w * 0.5 if side == 1 else -w * 0.5), hgt * 0.5, 0)
		b.box(off, Vector3(w * rng.randf_range(0.5, 1.0), hgt, 0.35) if along else Vector3(0.35, hgt, d * rng.randf_range(0.5, 1.0)), wallc)
	for i in 6:
		b.box(Vector3(rng.randf_range(-w, w) * 0.4, 0.15, rng.randf_range(-d, d) * 0.4), Vector3(rng.randf_range(0.4, 1.0), 0.3, rng.randf_range(0.4, 1.0)), wallc * rng.randf_range(0.7, 1.0))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = Arch.material(false)
	add(mi, p, rng.randf() * TAU)
	block(p, w * 0.8, d * 0.8)

## What prosperity adds or takes away, after the plan is laid out.
func _wealth_dressing() -> void:
	if kind == "temple":
		return
	var r := 40.0 if kind == "town" else (26.0 if kind == "castle" else 30.0)
	if wealth == 0:
		# debris, beggars by the gate, weeds, half the lanterns dark
		for i in 10 + (6 if kind == "town" else 0):
			var p := Vector3(rng.randf_range(-r, r), 0, rng.randf_range(-r, r))
			if free_at(p, 1.2):
				prop(["Crate_Wooden", "Barrel", "Bag", "Rock_Medium_1"][rng.randi() % 4], p, rng.randf() * TAU, rng.randf_range(0.6, 0.9), 0.4)
		# beggars on upturned crates at the roadside, facing the passers-by
		for i in 3:
			var bp := Vector3(-4.2 - i * 1.3, 0, r * 0.55 + i * 0.4)
			if free_at(bp, 0.5):
				prop("Crate_Wooden", bp + Vector3(-0.15, 0, 0), 0.0, 0.55, 0.0)
				npc_spot(bp, PI * 0.5, "sit", "", {"look": "beggar"})
		var keep := []
		for i in lights.size():
			if i % 2 == 0:
				keep.append(lights[i])
		lights = keep
	elif wealth == 2:
		# gardens, more lanterns and more people in the streets
		for i in 8:
			var a := TAU * i / 8.0
			var p := Vector3(cos(a) * r * 0.45, 0, sin(a) * r * 0.45)
			if free_at(p, 2.0):
				if ice:
					street_lantern(p, a)
				else:
					tree(p)
		for i in 6:
			var p2: Vector3 = waypoints[rng.randi() % waypoints.size()] if not waypoints.is_empty() else Vector3.ZERO
			if free_at(p2 + Vector3(1.5, 0, 0), 0.6):
				street_lantern(p2 + Vector3(1.5, 0, 0), rng.randf() * TAU)
		for i in 6:
			var sp: Vector3 = waypoints[rng.randi() % waypoints.size()] if not waypoints.is_empty() else Vector3.ZERO
			npc_spot(sp + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)), rng.randf() * TAU, "talk")

static var _wealth_mats := {}

## Poor houses are grimy and faded, rich ones fresh; middling ones as built.
func _weather(n: Node) -> void:
	if wealth == 1:
		return
	if not _wealth_mats.has(wealth):
		var m: ShaderMaterial = Arch.material(false).duplicate()
		m.set_shader_parameter("tint", Color(0.7, 0.66, 0.6) if wealth == 0 else Color(1.06, 1.04, 1.02))
		m.set_shader_parameter("brush_strength", 0.22 if wealth == 0 else 0.06)
		_wealth_mats[wealth] = m
	for mi in n.find_children("*", "MeshInstance3D", true, false) + ([n] if n is MeshInstance3D else []):
		(mi as MeshInstance3D).material_override = _wealth_mats[wealth]
