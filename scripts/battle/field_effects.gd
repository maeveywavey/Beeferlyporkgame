extends Node3D
## What bending leaves behind on a battlefield.
##
## The field is a grid of 2 m cells. Each cell has fuel (dry grass burns,
## snow and sand do not), wetness and a fire. Fire on fuel burns for a while,
## spreads to dry neighbours (faster with wind, slower in rain), hurts anyone
## standing in it and leaves the ground scorched and spent. Water soaks cells
## and the people it hits; wet ground does not catch, wet people burn less and
## take more from lightning, and puddles dry over a minute or so. Wind fans
## flames ahead of it or, as Clearing Wind, blows them out.
##
## Earth stays where it is put: walls stand for the rest of the battle (the
## oldest crumble when there are too many), pillars raised under enemies
## remain as columns to fight around, and thrown rocks stay where they land.

const MB = preload("res://scripts/world/map_builder.gd")

const CELL := 2.0
const MAX_FIRES := 90
const MAX_ROCKS := 70
const MAX_STRUCTURES := 24

var battle
var n := 0                       # cells per side
var half := 0.0
var fuel: PackedFloat32Array     # 0..1
var wet: PackedFloat32Array      # seconds of wetness left
var fire: PackedFloat32Array     # seconds of burning left
var scorched: PackedByteArray
var rain := false
var wind := Vector2.ZERO
var _fire_nodes := {}            # cell index -> flame node
var _puddles := {}               # cell index -> puddle node
var _scorch_mm: MultiMesh
var _rocks: Array = []
var structures: Array = []       # earth walls and pillars, oldest first
var _tick := 0.0

func setup(p_battle, biome: String, p_rain: bool) -> void:
	battle = p_battle
	half = battle.HALF
	n = int(half * 2.0 / CELL)
	rain = p_rain
	fuel.resize(n * n)
	wet.resize(n * n)
	fire.resize(n * n)
	scorched.resize(n * n)
	var base: float = {"grass": 0.75, "forest": 0.9, "highland": 0.6, "swamp": 0.25, "volcanic": 0.3,
		"mountain": 0.3, "desert": 0.05, "snow": 0.0, "beach": 0.1}.get(biome, 0.5)
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.08
	for i in n * n:
		var x := (i % n) * CELL - half
		var z := int(i / n) * CELL - half
		fuel[i] = clampf(base + noise.get_noise_2d(x, z) * 0.35, 0.0, 1.0)
		if rain:
			wet[i] = 9999.0
	wind = Vector2.from_angle(randf() * TAU) * randf_range(0.0, 1.0)
	# scorch marks: one multimesh of dark ground quads
	_scorch_mm = MultiMesh.new()
	_scorch_mm.transform_format = MultiMesh.TRANSFORM_3D
	_scorch_mm.use_colors = true
	var qm := QuadMesh.new()
	qm.size = Vector2(CELL * 1.25, CELL * 1.25)
	qm.orientation = PlaneMesh.FACE_Y
	var sm := StandardMaterial3D.new()
	sm.vertex_color_use_as_albedo = true
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.material = sm
	_scorch_mm.mesh = qm
	_scorch_mm.instance_count = n * n
	_scorch_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _scorch_mm
	add_child(mmi)

func _idx(p: Vector3) -> int:
	var cx := int((p.x + half) / CELL)
	var cz := int((p.z + half) / CELL)
	if cx < 0 or cz < 0 or cx >= n or cz >= n:
		return -1
	return cz * n + cx

func _center(i: int) -> Vector3:
	var x := (i % n) * CELL - half + CELL * 0.5
	var z := int(i / n) * CELL - half + CELL * 0.5
	return Vector3(x, battle.ground_height(x, z), z)

# ---------------------------------------------------------------------------
# Fire
# ---------------------------------------------------------------------------
## Try to set the ground alight in a radius around p. Returns cells lit.
func ignite(p: Vector3, radius: float = 1.0, strength: float = 1.0) -> int:
	var lit := 0
	var r := int(ceil(radius / CELL))
	var c := _idx(p)
	if c < 0:
		return 0
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var i := c + dz * n + dx
			if i < 0 or i >= n * n or absi((i % n) - (c % n)) > r:
				continue
			if _light(i, strength):
				lit += 1
	return lit

func _light(i: int, strength: float) -> bool:
	if fire[i] > 0.0 or wet[i] > 0.0 or scorched[i] == 1 or fuel[i] < 0.12:
		return false
	if randf() > fuel[i] * strength:
		return false
	if _fire_nodes.size() >= MAX_FIRES:
		return false
	fire[i] = randf_range(5.0, 9.0) * (0.6 + fuel[i] * 0.6)
	var fl := _flame()
	add_child(fl)
	fl.position = _center(i) + Vector3(randf_range(-0.5, 0.5), 0.0, randf_range(-0.5, 0.5))
	_fire_nodes[i] = fl
	return true

func _flame() -> Node3D:
	var root := Node3D.new()
	var p := CPUParticles3D.new()
	p.amount = 14
	p.lifetime = 0.7
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.7
	p.direction = Vector3.UP
	p.spread = 15.0
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.6
	p.gravity = Vector3(wind.x * 1.5, 1.5, wind.y * 1.5)
	var qm := QuadMesh.new()
	qm.size = Vector2(0.55, 0.75)
	var m := _soft_material()
	qm.material = m
	p.mesh = qm
	p.material_override = m
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.35, 0.95))
	g.add_point(0.45, Color(1.0, 0.4, 0.08, 0.85))
	g.set_color(g.get_point_count() - 1, Color(0.25, 0.22, 0.2, 0.0))
	p.color_ramp = g
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.6))
	sc.add_point(Vector2(0.4, 1.0))
	sc.add_point(Vector2(1, 0.3))
	p.scale_amount_curve = sc
	root.add_child(p)
	# smoke
	var s := CPUParticles3D.new()
	s.amount = 5
	s.lifetime = 2.2
	s.direction = Vector3.UP
	s.spread = 20.0
	s.initial_velocity_min = 1.0
	s.initial_velocity_max = 1.8
	s.gravity = Vector3(wind.x * 2.0, 0.6, wind.y * 2.0)
	var sq := QuadMesh.new()
	sq.size = Vector2(1.1, 1.1)
	sq.material = m
	s.mesh = sq
	s.material_override = m
	var sg := Gradient.new()
	sg.set_color(0, Color(0.55, 0.53, 0.5, 0.28))
	sg.set_color(1, Color(0.7, 0.7, 0.7, 0.0))
	s.color_ramp = sg
	s.position.y = 1.0
	root.add_child(s)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.2)
	light.light_energy = 0.6
	light.omni_range = 4.0
	light.position.y = 0.8
	root.add_child(light)
	return root

static var _soft: StandardMaterial3D

## A soft round sprite for flames and smoke, tinted by the particle colour.
static func _soft_material() -> StandardMaterial3D:
	if _soft != null:
		return _soft
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.add_point(0.55, Color(1, 1, 1, 0.75))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 32
	gt.height = 32
	_soft = StandardMaterial3D.new()
	_soft.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_soft.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_soft.vertex_color_use_as_albedo = true
	_soft.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_soft.albedo_texture = gt
	_soft.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	_soft.disable_receive_shadows = true
	_soft.shadow_to_opacity = false
	return _soft

func extinguish(p: Vector3, radius: float) -> int:
	var out := 0
	for i in _fire_nodes.keys():
		if _center(i).distance_to(p) <= radius + CELL * 0.5:
			_put_out(i, false)
			out += 1
	return out

func _put_out(i: int, burnt: bool) -> void:
	fire[i] = 0.0
	if _fire_nodes.has(i):
		var fl: Node3D = _fire_nodes[i]
		_fire_nodes.erase(i)
		var p := fl.get_child(0) as CPUParticles3D
		if p:
			p.emitting = false
		get_tree().create_timer(2.5).timeout.connect(fl.queue_free)
	if burnt and scorched[i] == 0:
		scorched[i] = 1
		fuel[i] = 0.0
		var k := _scorch_mm.visible_instance_count
		var c := _center(i) + Vector3(0, 0.04, 0)
		_scorch_mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, randf() * TAU), c))
		_scorch_mm.set_instance_color(k, Color(0.08, 0.07, 0.06, randf_range(0.65, 0.85)))
		_scorch_mm.visible_instance_count = k + 1

# ---------------------------------------------------------------------------
# Water
# ---------------------------------------------------------------------------
## Soak the ground in a radius (puts out fire, leaves puddles that dry).
func soak(p: Vector3, radius: float = 1.0, seconds: float = 45.0) -> void:
	var r := int(ceil(radius / CELL))
	var c := _idx(p)
	if c < 0:
		return
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var i := c + dz * n + dx
			if i < 0 or i >= n * n or absi((i % n) - (c % n)) > r:
				continue
			if fire[i] > 0.0:
				_put_out(i, false)
			wet[i] = maxf(wet[i], seconds * randf_range(0.8, 1.2))
			if not _puddles.has(i) and not rain and _puddles.size() < 160:
				var pd := _puddle()
				add_child(pd)
				pd.position = _center(i) + Vector3(randf_range(-0.4, 0.4), 0.05, randf_range(-0.4, 0.4))
				_puddles[i] = pd

func _puddle() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = randf_range(0.7, 1.2)
	cm.bottom_radius = cm.top_radius
	cm.height = 0.02
	cm.radial_segments = 10
	mi.mesh = cm
	mi.scale = Vector3(1.0, 1.0, randf_range(0.6, 1.0))
	mi.rotation.y = randf() * TAU
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.12, 0.16, 0.2, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	m.metallic = 0.3
	mi.material_override = m
	return mi

func is_wet(p: Vector3) -> bool:
	var i := _idx(p)
	return i >= 0 and wet[i] > 0.0

# ---------------------------------------------------------------------------
# Wind
# ---------------------------------------------------------------------------
## A gust from `from` along `dir`: fans fires it crosses forward a few cells.
func gust(from: Vector3, dir: Vector3, length: float) -> void:
	var d := Vector2(dir.x, dir.z).normalized()
	for i in _fire_nodes.keys():
		var c := _center(i)
		var rel := Vector2(c.x - from.x, c.z - from.z)
		var along := rel.dot(d)
		if along > 0.0 and along < length and absf(rel.cross(d)) < 2.5:
			for k in range(1, 3):
				var tgt := c + Vector3(d.x, 0, d.y) * CELL * k
				var j := _idx(tgt)
				if j >= 0:
					_light(j, 1.4)

# ---------------------------------------------------------------------------
# Earth
# ---------------------------------------------------------------------------
## Walls and pillars stay; when there are too many, the oldest crumbles.
func add_structure(rec: Dictionary) -> void:
	structures.append(rec)
	while structures.size() > MAX_STRUCTURES:
		var old: Dictionary = structures.pop_front()
		battle.crumble_structure(old)

## A rock that stays where it fell.
func leave_rock(p: Vector3, size: float = 1.0) -> void:
	var r := MB.sphere(0.3 * size, Color(0.45, 0.38, 0.3).darkened(randf() * 0.2), Vector3(p.x, battle.ground_height(p.x, p.z) + 0.08 * size, p.z))
	r.scale = Vector3(randf_range(0.9, 1.3), randf_range(0.5, 0.8), randf_range(0.9, 1.3))
	r.rotation = Vector3(randf() * 0.4, randf() * TAU, randf() * 0.4)
	add_child(r)
	_rocks.append(r)
	if _rocks.size() > MAX_ROCKS:
		var old: Node3D = _rocks.pop_front()
		if is_instance_valid(old):
			old.queue_free()

# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	_tick += delta
	if _tick < 0.25:
		return
	var dt := _tick
	_tick = 0.0
	for i in _fire_nodes.keys():
		fire[i] -= dt * (2.0 if rain else 1.0)
		if fire[i] <= 0.0:
			_put_out(i, true)
			continue
		# spread to a neighbour, downwind more readily
		if randf() < dt * (0.25 if rain else 0.75):
			var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			var d: Vector2i = dirs[randi() % 4]
			var w := 1.0 + Vector2(d).dot(wind) * 0.8
			var cx: int = (i % n) + d.x
			var cz: int = int(i / n) + d.y
			if cx >= 0 and cz >= 0 and cx < n and cz < n:
				_light(cz * n + cx, 0.55 * w)
	if not rain:
		for i in _puddles.keys():
			wet[i] -= dt
			var pd: MeshInstance3D = _puddles[i]
			if wet[i] <= 0.0:
				_puddles.erase(i)
				pd.queue_free()
			elif wet[i] < 10.0:
				(pd.material_override as StandardMaterial3D).albedo_color.a = 0.55 * wet[i] / 10.0
	# people standing in fire catch it
	if not _fire_nodes.is_empty():
		for t in 2:
			for u in battle.team_units[t]:
				if not u.alive:
					continue
				var i := _idx(u.position)
				if i >= 0 and fire[i] > 0.0 and u.wet_t <= 0.0:
					u.burn_t = maxf(u.burn_t, 1.5)
					u.burn_dps = maxf(u.burn_dps, 4.0)

func burning_cells() -> int:
	return _fire_nodes.size()
