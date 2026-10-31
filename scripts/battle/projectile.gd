extends Node3D
## A projectile in battle: arrows, thrown weapons and bending attacks.
## Movement and collision are handled manually against units, walls and terrain.

const Bending = preload("res://scripts/battle/bending.gd")
const FlameSprite = preload("res://scripts/battle/flame_sprite.gd")
const MB = preload("res://scripts/world/map_builder.gd")

var battle
var owner_unit
var team := 0
var vel := Vector3.ZERO
var gravity := 0.0
var dmg := 10.0
var dtype := "pierce"
var radius := 0.15
var knock := 1.0
var effect := ""
var fx := "arrow"
var life := 4.0
var pierce := false
var hit_units := []
var spin := false

func setup(p: Dictionary) -> void:
	for k in p:
		set(k, p[k])
	_build_visual()

func _build_visual() -> void:
	var c := Bending.fx_color(fx)
	match fx:
		"arrow":
			var b := BoxMesh.new()
			b.size = Vector3(0.03, 0.03, 0.8)
			var mi := MeshInstance3D.new()
			mi.mesh = b
			mi.material_override = MB.mat(c)
			add_child(mi)
		"boomerang", "knife":
			var bb := BoxMesh.new()
			bb.size = Vector3(0.45, 0.04, 0.08) if fx == "boomerang" else Vector3(0.04, 0.03, 0.3)
			var m2 := MeshInstance3D.new()
			m2.mesh = bb
			m2.material_override = MB.mat(Color(0.5, 0.35, 0.2) if fx == "boomerang" else Color(0.8, 0.8, 0.85))
			add_child(m2)
			spin = fx == "boomerang"
		"rock":
			# a real boulder torn from the ground (nature kit rock, painted)
			var rk: Node3D = load("res://scripts/battle/set_dressing.gd").rock(radius * 0.9, Color(0.95, 0.88, 0.78))
			add_child(rk)
			spin = true
		"ice":
			var cn := CylinderMesh.new()
			cn.top_radius = 0.0
			cn.bottom_radius = 0.12
			cn.height = 0.7
			var m4 := MeshInstance3D.new()
			m4.mesh = cn
			m4.rotation_degrees.x = 90
			m4.material_override = MB.mat(c, 0.2)
			add_child(m4)
		_:
			var sp := SphereMesh.new()
			sp.radius = radius * 0.8
			sp.height = radius * 1.6
			sp.radial_segments = 10
			sp.rings = 5
			if fx in ["fire", "blue_fire"]:
				# a hand-inked fireball: round head, curling tail trailing behind
				var fb := FlameSprite.make("fireball", Vector2(radius * 4.6, radius * 4.6), fx == "blue_fire", 3)
				add_child(fb)
				var light0 := OmniLight3D.new()
				light0.light_color = c
				light0.omni_range = 4.0
				light0.light_energy = 1.5
				add_child(light0)
				return
			var m5 := MeshInstance3D.new()
			m5.mesh = sp
			var unshaded := fx in ["fire", "blue_fire", "lightning"]
			m5.material_override = MB.mat(c, 0.3, unshaded)
			if fx == "water":
				m5.scale = Vector3(1, 1, 1.8)
			add_child(m5)
			if fx in ["fire", "blue_fire", "sand", "air", "water"]:
				var p := CPUParticles3D.new()
				p.amount = 18
				p.lifetime = 0.35
				p.local_coords = false
				p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
				p.emission_sphere_radius = radius * 0.6
				p.gravity = Vector3(0, 1.5 if fx in ["fire", "blue_fire"] else -2.0, 0)
				p.initial_velocity_min = 0.2
				p.initial_velocity_max = 1.0
				p.scale_amount_min = 0.5
				p.scale_amount_max = 1.0
				var pm := SphereMesh.new()
				pm.radius = radius * 0.35
				pm.height = radius * 0.7
				pm.radial_segments = 6
				pm.rings = 3
				p.mesh = pm
				p.material_override = MB.mat(c.lightened(0.2), 0.5, true)
				var grad := Gradient.new()
				grad.set_color(0, Color(1, 1, 1, 1))
				grad.set_color(1, Color(1, 1, 1, 0))
				p.color_ramp = grad
				add_child(p)
			if fx in ["fire", "blue_fire"]:
				var light := OmniLight3D.new()
				light.light_color = c
				light.omni_range = 4.0
				light.light_energy = 1.5
				add_child(light)

func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	vel.y -= gravity * delta
	var old := position
	position += vel * delta
	if vel.length() > 0.1:
		var look_target := position + vel
		if not look_target.is_equal_approx(position) and absf(vel.normalized().dot(Vector3.UP)) < 0.99:
			look_at(look_target, Vector3.UP)
			rotate_object_local(Vector3.UP, PI)
	if spin:
		rotate_object_local(Vector3.UP, delta * 20.0)
	# a bolt or ball passing the camera shrinks away instead of filling the screen
	if fx not in ["arrow", "boomerang", "knife", "rock", "ice"]:
		var cam: Camera3D = battle.cam if battle != null else null
		if cam != null:
			scale = Vector3.ONE * clampf((global_position.distance_to(cam.global_position) - 1.5) / 2.0, 0.0, 1.0)
	# Terrain
	var gh: float = battle.ground_height(position.x, position.z)
	if position.y < gh:
		_impact(null)
		return
	# Walls
	if battle.point_in_wall(position):
		_impact(null)
		return
	# Units (segment sampling for fast projectiles)
	var steps := int(ceil((position - old).length() / 0.4))
	for i in range(1, steps + 1):
		var p := old.lerp(position, float(i) / steps)
		var u = battle.unit_hit_by_point(p, radius, team, hit_units)
		if u != null:
			if pierce:
				hit_units.append(u)
				battle.projectile_hit(self, u)
			else:
				position = p
				battle.projectile_hit(self, u)
				_impact(u)
				return

func _impact(_u) -> void:
	if fx in ["fire", "blue_fire", "rock", "water", "sand", "ice"]:
		battle.spawn_burst(position, Bending.fx_color(fx), 1.0 if fx != "rock" else 1.4)
	var field = battle.field
	if field != null:
		match fx:
			"rock":
				if _u == null:
					field.leave_rock(position, clampf(radius * 1.6, 0.6, 2.2))
			"fire", "blue_fire":
				field.ignite(position, 1.0, 0.9)
			"water":
				field.soak(position, 1.4)
				if _u != null:
					_u.wet_t = 20.0
			"ice":
				field.soak(position, 0.6, 20.0)
				if _u != null:
					_u.wet_t = 12.0
	queue_free()
