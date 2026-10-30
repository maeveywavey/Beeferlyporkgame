extends Node
## The Avatar's wrath: what happens when an Avatar, furious at a conqueror's
## cruelty, enters the Avatar State on the field. Over a dozen seconds the four
## elements answer at once:
##   earth — cracks race out across the ground and stone spikes burst up under
##           the enemy, impaling them
##   fire  — a ring of fire rolls out from the Avatar and roasts those it meets
##   air   — a vortex tears every tree near the Avatar out of the ground and
##           throws trees and soldiers like loose paper
##   water — on a coast, the sea rises into a wall and sweeps the field;
##           inland, the water is drawn up from the ground
## The Avatar rises into the air while it happens, and the camera shakes.

const Gore = preload("res://scripts/battle/gore.gd")

var battle
var avatar
var t := 0.0
var shake := 0.0
var _cracks: Array = []        # {"from", "dir", "len", "grown", "node"}
var _fire_r := 0.0
var _wave: Node3D
var _wave_x := 0.0
var _wave_h := 0.0
var _flying: Array = []        # {"node", "v", "spin", "rest"}
var _done := {}
var _swept := {}

func start(p_battle, p_avatar) -> void:
	battle = p_battle
	avatar = p_avatar
	avatar.root_t = 11.0
	battle.feed_msg("The ground, the sea and the sky answer the Avatar.", Color(0.85, 0.95, 1))

func _process(delta: float) -> void:
	if battle == null or not is_instance_valid(avatar):
		queue_free()
		return
	t += delta
	# the Avatar rises, holds, and comes down
	avatar.levitate = clampf(t / 1.2, 0.0, 1.0) * 3.2 if t < 11.0 else maxf(0.0, avatar.levitate - delta * 2.0)
	_once(0.8, _earth_begin)
	_once(2.2, _fire_begin)
	_once(3.4, _air_begin)
	_once(3.8, _water_begin)
	_grow_cracks(delta)
	_roll_fire(delta)
	_move_wave(delta)
	_fly(delta)
	shake = maxf(0.0, shake - delta * 0.8)
	if battle.cam != null and shake > 0.0:
		battle.cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shake * 0.25
	if t > 14.0:
		avatar.levitate = 0.0
		queue_free()

func _once(at: float, f: Callable) -> void:
	if t >= at and not _done.has(at):
		_done[at] = true
		f.call()

func _enemies() -> Array:
	return battle.team_units[1 - avatar.team].filter(func(u): return u.alive)

# ---------------------------------------------------------------------------
# Earth: cracks race out and spikes burst up under the enemy
# ---------------------------------------------------------------------------
func _earth_begin() -> void:
	shake = 1.6
	Sfx.play_at("earth", avatar.position, 4.0)
	var c: Vector3 = avatar.position
	for i in 16:
		var a := TAU * i / 16.0 + randf_range(-0.15, 0.15)
		_crack(c, Vector3(cos(a), 0, sin(a)), randf_range(24.0, 42.0))
	for u in _enemies():
		var d: Vector3 = u.position - c
		d.y = 0.0
		if d.length() < 40.0:
			_crack(c, d.normalized(), d.length() + 2.0, u)

func _crack(from: Vector3, dir: Vector3, length: float, victim = null) -> void:
	var node := Node3D.new()
	battle.add_child(node)
	_cracks.append({"from": from, "dir": dir, "len": length, "grown": 0.0, "node": node, "victim": victim, "wob": randf() * 10.0})

func _grow_cracks(delta: float) -> void:
	var dark := StandardMaterial3D.new() if _cracks.is_empty() else null
	for c in _cracks:
		if c.grown >= c.len:
			continue
		var step := minf(delta * 26.0, c.len - c.grown)
		var a: float = c.grown
		c.grown += step
		# a jagged dark seam, segment by segment
		var dir: Vector3 = c.dir
		var side := Vector3(-dir.z, 0, dir.x)
		var p0: Vector3 = c.from + dir * a + side * sin(a * 0.7 + c.wob) * 0.6
		var p1: Vector3 = c.from + dir * c.grown + side * sin(c.grown * 0.7 + c.wob) * 0.6
		var mid := (p0 + p1) * 0.5
		mid.y = battle.ground_height(mid.x, mid.z) + 0.04
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.35 + randf() * 0.3, 0.06, maxf(0.2, p0.distance_to(p1) + 0.1))
		seg.mesh = bm
		seg.material_override = _mat(Color(0.06, 0.04, 0.03))
		c.node.add_child(seg)
		seg.global_position = mid
		if not p0.is_equal_approx(p1):
			seg.look_at(Vector3(p1.x, mid.y, p1.z), Vector3.UP)
		if randf() < 0.25:
			battle.spawn_burst(mid + Vector3(0, 0.2, 0), Color(0.45, 0.36, 0.25), 0.6)
		if c.grown >= c.len and c.victim != null and is_instance_valid(c.victim) and c.victim.alive:
			_spike(c.victim)

## A stone spike bursts up under a soldier and impales them.
func _spike(u) -> void:
	var at: Vector3 = u.position
	var spike := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.02
	cm.bottom_radius = 0.45
	cm.height = 3.2
	cm.radial_segments = 6
	spike.mesh = cm
	spike.material_override = _mat(Color(0.42, 0.36, 0.3))
	battle.add_child(spike)
	var gh: float = battle.ground_height(at.x, at.z)
	spike.position = Vector3(at.x, gh - 1.6, at.z)
	spike.rotation = Vector3(randf_range(-0.25, 0.25), 0, randf_range(-0.25, 0.25))
	spike.create_tween().tween_property(spike, "position:y", gh + 1.3, 0.12)
	u.gore_hint = "impale"
	u.apply_damage(120.0 if u.lord_id == "" else 45.0, avatar, "blunt", Vector3.UP, 0.0, true)

# ---------------------------------------------------------------------------
# Fire: a ring of fire rolls out from the Avatar
# ---------------------------------------------------------------------------
func _fire_begin() -> void:
	shake = maxf(shake, 0.8)
	Sfx.play_at("fire", avatar.position, 4.0)
	_fire_r = 1.0

func _roll_fire(delta: float) -> void:
	if _fire_r <= 0.0 or _fire_r > 34.0:
		return
	var r0 := _fire_r
	_fire_r += delta * 14.0
	var c: Vector3 = avatar.position
	var n := int(_fire_r * 1.2)
	for i in n:
		var a := TAU * i / n
		var p := c + Vector3(cos(a), 0, sin(a)) * _fire_r
		if randf() < 0.18:
			battle.spawn_burst(Vector3(p.x, battle.ground_height(p.x, p.z) + 0.6, p.z), Color(1.0, 0.45, 0.1), 1.3)
		if battle.field != null and randf() < 0.3:
			battle.field.ignite(p, 1.0, 3.0)
	for u in _enemies():
		var d: float = Vector2(u.position.x - c.x, u.position.z - c.z).length()
		if d >= r0 - 1.0 and d < _fire_r + 1.0:
			u.gore_hint = "fire"
			u.burn_t = 8.0
			u.burn_dps = 9.0
			u.char_amt = maxf(u.char_amt, 0.4)
			u.apply_damage(30.0, avatar, "fire", (u.position - c).normalized(), 6.0, true)

# ---------------------------------------------------------------------------
# Air: a vortex tears up the trees and throws trees and soldiers
# ---------------------------------------------------------------------------
func _air_begin() -> void:
	shake = maxf(shake, 1.4)
	Sfx.play_at("air", avatar.position, 6.0)
	var c: Vector3 = avatar.position
	# a turning column of dust and leaves around the Avatar
	var p := CPUParticles3D.new()
	p.amount = 260
	p.lifetime = 2.5
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_radius = 6.0
	p.emission_ring_inner_radius = 2.0
	p.emission_ring_height = 1.0
	p.emission_ring_axis = Vector3.UP
	p.direction = Vector3.UP
	p.spread = 10.0
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 16.0
	p.orbit_velocity_min = 0.6
	p.orbit_velocity_max = 1.0
	p.radial_accel_min = 2.0
	p.radial_accel_max = 6.0
	var qm := QuadMesh.new()
	qm.size = Vector2(0.5, 0.5)
	var m: StandardMaterial3D = load("res://scripts/battle/field_effects.gd")._soft_material().duplicate()
	qm.material = m
	p.mesh = qm
	p.material_override = m
	p.color = Color(0.85, 0.82, 0.72, 0.55)
	battle.add_child(p)
	p.global_position = c
	get_tree().create_timer(6.0).timeout.connect(func(): p.emitting = false)
	get_tree().create_timer(9.0).timeout.connect(p.queue_free)
	# every tree in reach is torn out, lifted and flung
	for tr in battle.trees:
		var n: Node3D = tr.node
		if not is_instance_valid(n):
			continue
		var d := Vector2(tr.p.x - c.x, tr.p.y - c.z)
		if d.length() > 55.0:
			continue
		battle.obstacles.erase(tr.ob)
		var out := Vector3(d.x, 0, d.y).normalized()
		var delay := d.length() / 55.0 * 0.8
		_flying.append({"node": n, "v": out * randf_range(14.0, 26.0) + Vector3(0, randf_range(16.0, 26.0), 0),
			"spin": Vector3(randf_range(-3, 3), randf_range(-2, 2), randf_range(-3, 3)), "wait": delay, "rest": false})
	# and so is every soldier near the Avatar
	for u in _enemies():
		var dd: Vector3 = u.position - c
		dd.y = 0.0
		if dd.length() < 40.0 and not u.mounted():
			u.airborne = true
			u.y_vel = randf_range(14.0, 20.0)
			u.knock += dd.normalized() * randf_range(10.0, 18.0)

func _fly(delta: float) -> void:
	for f in _flying:
		if f.rest:
			continue
		if f.wait > 0.0:
			f.wait -= delta
			continue
		var n: Node3D = f.node
		if not is_instance_valid(n):
			f.rest = true
			continue
		f.v.y -= 12.0 * delta
		n.position += f.v * delta
		n.rotation += f.spin * delta
		var gh: float = battle.ground_height(n.position.x, n.position.z)
		if n.position.y < gh - 0.5 and f.v.y < 0.0:
			# it lands on its side and stays where it fell (or sinks offshore)
			n.position.y = maxf(gh, battle.SEA_LEVEL - 1.0)
			n.rotation.x = PI * 0.5 * signf(randf() - 0.5)
			f.rest = true
			battle.spawn_burst(n.position + Vector3(0, 0.4, 0), Color(0.4, 0.33, 0.24), 1.2)

# ---------------------------------------------------------------------------
# Water: the sea rises and sweeps the field
# ---------------------------------------------------------------------------
func _water_begin() -> void:
	shake = maxf(shake, 1.8)
	Sfx.play_at("water", avatar.position, 6.0)
	_wave = Node3D.new()
	battle.add_child(_wave)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(9.0, 1.0, 190.0)
	body.mesh = bm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.18, 0.36, 0.42, 0.82)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.roughness = 0.08
	wm.metallic_specular = 0.8
	body.material_override = wm
	_wave.add_child(body)
	var foam := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(10.0, 0.6, 192.0)
	foam.mesh = fm
	foam.material_override = _mat(Color(0.86, 0.92, 0.94))
	foam.name = "Foam"
	_wave.add_child(foam)
	# on a coast the wave comes out of the sea; inland it is drawn up beside the Avatar
	_wave_x = battle.shore_x + 6.0 if battle.coast else avatar.position.x + 30.0
	_wave_h = 0.0
	_wave.position = Vector3(_wave_x, battle.SEA_LEVEL, avatar.position.z)

func _move_wave(delta: float) -> void:
	if _wave == null or not is_instance_valid(_wave):
		return
	var age := t - 3.8
	var body: MeshInstance3D = _wave.get_child(0)
	var foam: MeshInstance3D = _wave.get_child(1)
	if age < 1.6:
		_wave_h = lerpf(0.5, 10.0, age / 1.6)
	elif age < 5.0:
		_wave_x -= delta * 24.0
	else:
		_wave_h = maxf(0.0, _wave_h - delta * 5.0)
		if _wave_h <= 0.01:
			_wave.queue_free()
			_wave = null
			return
	body.scale.y = _wave_h
	body.position.y = _wave_h * 0.5
	foam.position.y = _wave_h + 0.1
	foam.position.x = -1.2
	_wave.position.x = _wave_x
	if age >= 1.6 and age < 5.0:
		for u in battle.team_units[1 - avatar.team]:
			if not u.alive or _swept.has(u):
				continue
			if absf(u.position.x - _wave_x) < 5.0:
				_swept[u] = true
				u.wet_t = 30.0
				u.burn_t = 0.0
				u.gore_hint = "fall"
				if not u.mounted():
					u.airborne = true
					u.y_vel = randf_range(6.0, 11.0)
				u.knock += Vector3(-1, 0, randf_range(-0.3, 0.3)) * randf_range(22.0, 32.0)
				u.apply_damage(55.0, avatar, "blunt", Vector3(-1, 0, 0), 4.0, true)
		if battle.field != null:
			battle.field.soak(Vector3(_wave_x, 0, avatar.position.z), 8.0, 60.0)
		if randf() < 0.6:
			var z: float = avatar.position.z + randf_range(-70.0, 70.0)
			battle.spawn_burst(Vector3(_wave_x - 3.0, _wave_h, z), Color(0.85, 0.92, 0.95), 2.0)

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m
