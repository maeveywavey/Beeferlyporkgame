extends RefCounted
## Wounds that show. When gore is on (Settings: Gore and dismemberment), how a
## fighter dies decides what is left of them:
##   blade / water slice — an arm, a leg or the head is cut away, flies off and
##                         lands; the stump spurts and a pool spreads
##   impaling earth      — a stone pillar or a heavy rock tears the body open:
##                         guts and gore burst out and the body is thrown
##   falling             — thrown high by wind, a fighter breaks a limb on the
##                         ground: the leg or arm bends the wrong way, and the
##                         living limp
##   fire                — burned alive: the body blackens as it burns, the
##                         living run and flail, the dead keep smouldering
## Severed and broken bones are applied after animation by a skeleton modifier.

const CB = preload("res://scripts/actors/character_builder.gd")
const FlameSprite = preload("res://scripts/battle/flame_sprite.gd")

const LIMBS := {
	"arm_l": ["upperarm_l", 0.55], "arm_r": ["upperarm_r", 0.55], "forearm_l": ["lowerarm_l", 0.4],
	"forearm_r": ["lowerarm_r", 0.4], "leg_l": ["thigh_l", 0.8], "leg_r": ["thigh_r", 0.8],
	"shin_l": ["calf_l", 0.5], "shin_r": ["calf_r", 0.5], "head": ["Head", 0.24],
}
const BLOOD := Color(0.42, 0.02, 0.02)
const BLOOD_DARK := Color(0.22, 0.01, 0.01)

static func enabled() -> bool:
	return GS.settings.get("gore", true)

## Called when a unit dies; `hint` says what killed it (set by the battle
## just before the killing blow).
static func on_death(battle, u, dtype: String, hint: String) -> void:
	if not enabled() or not u.parts.has("actor"):
		return
	# wounds nobody walks away from: the fallen is counted dead, not wounded
	if hint in ["impale", "fire"]:
		u.set_meta("gored", true)
	match hint:
		"blade", "water_slice":
			if randf() < 0.6:
				var keys := ["arm_l", "arm_r", "forearm_l", "forearm_r", "leg_l", "leg_r", "shin_l", "shin_r"]
				if randf() < 0.18:
					sever(battle, u, "head")
				else:
					sever(battle, u, keys.pick_random())
			else:
				bleed(battle, u, 1.0)
		"impale":
			disembowel(battle, u)
		"fall":
			break_limb(u, ["shin_l", "shin_r", "forearm_l", "forearm_r"].pick_random())
			bleed(battle, u, 0.6)
		"fire":
			char_body(u, 1.0)
			smoulder(battle, u)
		_:
			if dtype in ["cut", "pierce"]:
				bleed(battle, u, 0.7)

# ---------------------------------------------------------------------------
static func _mod(u):
	var skel: Skeleton3D = u.parts.actor.parts.skeleton
	var m = skel.get_node_or_null("GoreMod")
	if m == null:
		m = GoreMod.new()
		m.name = "GoreMod"
		skel.add_child(m)
		m.skel = skel
	return m

## Cut a limb away: the bone collapses on the body, a limb flies off.
static func sever(battle, u, limb: String) -> void:
	u.set_meta("gored", true)
	var spec: Array = LIMBS[limb]
	var skel: Skeleton3D = u.parts.actor.parts.skeleton
	var bi := skel.find_bone(spec[0])
	if bi < 0:
		return
	var at: Vector3 = (skel.global_transform * skel.get_bone_global_pose(bi)).origin
	_mod(u).severed.append(bi)
	var look: Dictionary = u.parts.actor.look
	var cloth: Color = look.get("cloth_tint", CB.PALETTES.get(look.get("culture", "earth"), CB.PALETTES.earth).primary)
	var piece := _limb_mesh(spec[1], Color(0.74, 0.55, 0.42) if limb == "head" else cloth, limb == "head")
	battle.add_child(piece)
	piece.global_position = at
	var out: Vector3 = (at - u.position)
	out.y = 0.0
	out = out.normalized() if out.length() > 0.01 else Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
	_fly(battle, piece, out * randf_range(3.0, 6.0) + Vector3(0, randf_range(3.5, 6.0), 0))
	_spurt(battle, at, 1.6)
	_pool(battle, u.position, 1.1)
	_pool(battle, at + out * 2.0, 0.5)

## Guts and gore burst out and the body is thrown up.
static func disembowel(battle, u) -> void:
	var c: Vector3 = u.position + Vector3(0, 1.0, 0)
	for i in 14:
		var bit := MeshInstance3D.new()
		if i % 3 == 0:
			var cm := CapsuleMesh.new()
			cm.radius = randf_range(0.04, 0.07)
			cm.height = randf_range(0.3, 0.6)
			bit.mesh = cm
		else:
			var sm := SphereMesh.new()
			sm.radius = randf_range(0.05, 0.11)
			sm.height = sm.radius * 1.6
			sm.radial_segments = 6
			sm.rings = 3
			bit.mesh = sm
		bit.material_override = _flesh_mat([Color(0.62, 0.22, 0.24), Color(0.48, 0.08, 0.08), Color(0.7, 0.42, 0.4)][i % 3])
		battle.add_child(bit)
		bit.global_position = c + Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
		_fly(battle, bit, Vector3(randf_range(-4, 4), randf_range(3, 8), randf_range(-4, 4)))
	_spurt(battle, c, 2.6)
	_pool(battle, u.position, 1.8)
	# the corpse is thrown up and comes down
	var tw: Tween = u.create_tween()
	var y0: float = u.position.y
	tw.tween_property(u, "position:y", y0 + 2.2, 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(u, "position:y", y0, 0.4).set_ease(Tween.EASE_IN)

## A limb bent the wrong way.
static func break_limb(u, limb: String) -> void:
	var skel: Skeleton3D = u.parts.actor.parts.skeleton
	var bi := skel.find_bone(LIMBS[limb][0])
	if bi < 0:
		return
	var axis := Vector3(randf_range(-1, 1), 0, 1).normalized()
	_mod(u).broken[bi] = Quaternion(axis, deg_to_rad(randf_range(70.0, 110.0)) * (1.0 if randf() < 0.5 else -1.0))

## Blackened skin and clothes, from 0 (none) to 1 (burned to the bone).
static func char_body(u, amount: float) -> void:
	var a := clampf(amount, 0.0, 1.0)
	var m: StandardMaterial3D = u.get_meta("char_mat") if u.has_meta("char_mat") else null
	if m == null:
		m = StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.emission_enabled = false
		u.set_meta("char_mat", m)
		for mi in u.parts.actor.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_overlay = m
	m.albedo_color = Color(0.05, 0.035, 0.03, a * 0.92)

## Flames that keep licking a burned body for a while.
static func smoulder(battle, u) -> void:
	# the dead burn on: a few small hand-inked flames and a thread of smoke
	var at: Vector3 = u.position
	for k in 3:
		var sz := randf_range(0.7, 1.0)
		var f := FlameSprite.puff(battle, at + Vector3(randf_range(-0.5, 0.5), 0.1, randf_range(-0.5, 0.5)), Vector2(sz, sz * 1.3), randf_range(5.0, 7.0))
		f.global_position.y = battle.ground_height(f.global_position.x, f.global_position.z) + 0.1
	var sm := FlameSprite.make("smoke", Vector2(1.0, 1.0), false, 1)
	battle.add_child(sm)
	sm.global_position = at + Vector3(0, 1.0, 0)
	battle.get_tree().create_timer(7.0).timeout.connect(func(): if is_instance_valid(sm): sm.queue_free())

## A spray of blood and a pool, for wounds without a cut-off limb.
static func bleed(battle, u, size: float) -> void:
	_spurt(battle, u.position + Vector3(0, 1.0, 0), size)
	_pool(battle, u.position, 0.9 * size)

# ---------------------------------------------------------------------------
static func _flesh_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.35
	return m

static func _limb_mesh(length: float, col: Color, head: bool) -> Node3D:
	var root := Node3D.new()
	var skin := Color(0.74, 0.55, 0.42)
	if head:
		var sm := SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.26
		var mi := MeshInstance3D.new()
		mi.mesh = sm
		mi.material_override = _flesh_mat(skin)
		root.add_child(mi)
		# the neck, torn
		_disc(root, Vector3(0, -0.12, 0), 0.07, Vector3.ZERO, true)
		return root
	var r0 := 0.062 if length < 0.6 else 0.085
	var r1 := r0 * 0.78
	# limbs lie along X: the cut end at +X, the hand or foot at -X
	if length < 0.6:
		_seg(root, -length * 0.5, -length * 0.15, r1 * 0.9, r1, skin)
		_seg(root, -length * 0.15, length * 0.5, r1, r0, col)
		var hand := SphereMesh.new()
		hand.radius = 0.06
		hand.height = 0.1
		var hm := MeshInstance3D.new()
		hm.mesh = hand
		hm.material_override = _flesh_mat(skin)
		hm.position = Vector3(-length * 0.5 - 0.03, 0, 0)
		root.add_child(hm)
	else:
		_seg(root, -length * 0.5, length * 0.5, r1, r0, col)
		var boot := BoxMesh.new()
		boot.size = Vector3(0.24, 0.12, 0.11)
		var bm := MeshInstance3D.new()
		bm.mesh = boot
		bm.material_override = _flesh_mat(Color(0.18, 0.13, 0.1))
		bm.position = Vector3(-length * 0.5 - 0.06, -0.02, 0)
		root.add_child(bm)
	_disc(root, Vector3(length * 0.5, 0, 0), r0, Vector3(0, 0, 90), true)
	return root

## A tapered segment of a limb along X from x0 to x1.
static func _seg(parent: Node3D, x0: float, x1: float, ra: float, rb: float, col: Color) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = rb
	cm.bottom_radius = ra
	cm.height = x1 - x0
	cm.radial_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.rotation_degrees.z = -90.0
	mi.position = Vector3((x0 + x1) * 0.5, 0, 0)
	mi.material_override = _flesh_mat(col)
	parent.add_child(mi)

## A cut face: red flesh with a pale bone end.
static func _disc(parent: Node3D, at: Vector3, r: float, rot_deg: Vector3, bone: bool) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = r * 0.96
	cm.bottom_radius = r * 0.96
	cm.height = 0.02
	cm.radial_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.position = at
	mi.rotation_degrees = rot_deg
	mi.material_override = _flesh_mat(Color(0.5, 0.05, 0.05))
	parent.add_child(mi)
	if bone:
		var bm := CylinderMesh.new()
		bm.top_radius = r * 0.3
		bm.bottom_radius = r * 0.3
		bm.height = 0.05
		bm.radial_segments = 6
		var bi := MeshInstance3D.new()
		bi.mesh = bm
		bi.position = at
		bi.rotation_degrees = rot_deg
		bi.material_override = _flesh_mat(Color(0.88, 0.84, 0.74))
		parent.add_child(bi)

## Throw a piece: it arcs, tumbles and lies where it lands.
static func _fly(battle, n: Node3D, vel: Vector3) -> void:
	var spin := Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9))
	var state := {"v": vel}
	var timer := Timer.new()
	timer.wait_time = 1.0 / 60.0
	n.add_child(timer)
	timer.timeout.connect(func():
		var dt := timer.wait_time
		state.v.y -= 16.0 * dt
		n.position += state.v * dt
		n.rotation += spin * dt
		var gh: float = battle.ground_height(n.position.x, n.position.z) + 0.06
		if n.position.y <= gh:
			n.position.y = gh
			if absf(state.v.y) < 2.0:
				timer.stop()
				_pool(battle, n.position, 0.35)
				return
			state.v = Vector3(state.v.x * 0.4, -state.v.y * 0.25, state.v.z * 0.4)
			spin *= 0.4)
	timer.start()
	battle.get_tree().create_timer(40.0).timeout.connect(func():
		if is_instance_valid(n):
			n.queue_free())

static func _spurt(battle, at: Vector3, size: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = int(30 * size)
	p.lifetime = 0.9
	p.explosiveness = 0.6
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 2.0 * size
	p.initial_velocity_max = 5.5 * size
	p.gravity = Vector3(0, -14, 0)
	var sm := SphereMesh.new()
	sm.radius = 0.04
	sm.height = 0.08
	sm.radial_segments = 5
	sm.rings = 2
	sm.material = _flesh_mat(BLOOD)
	p.mesh = sm
	battle.add_child(p)
	p.global_position = at
	battle.get_tree().create_timer(2.0).timeout.connect(p.queue_free)

## A pool of blood: an irregular spread of overlapping puddles that widens
## over a few seconds, then darkens as it dries.
static func _pool(battle, at: Vector3, r: float) -> void:
	var root := Node3D.new()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.27, 0.015, 0.015, 0.94)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.8
	m.metallic_specular = 0.15
	battle.add_child(root)
	root.global_position = Vector3(at.x, 0, at.z)
	for i in 5:
		var off := Vector2.from_angle(randf() * TAU) * r * randf_range(0.0, 0.6)
		var pr := r * randf_range(0.45, 0.8)
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = pr
		cm.bottom_radius = pr
		cm.height = 0.012
		cm.radial_segments = 14
		mi.mesh = cm
		mi.material_override = m
		root.add_child(mi)
		mi.global_position = Vector3(at.x + off.x, battle.ground_height(at.x + off.x, at.z + off.y) + 0.03 + i * 0.002, at.z + off.y)
		mi.scale = Vector3(0.15, 1.0, 0.15 * randf_range(0.6, 1.0))
		mi.rotation.y = randf() * TAU
		mi.create_tween().tween_property(mi, "scale", Vector3(1.0, 1.0, randf_range(0.6, 1.0)), randf_range(2.0, 4.0))
	var tw: Tween = root.create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(m, "albedo_color", Color(0.15, 0.025, 0.02, 0.9), 25.0)

## Applies severed (collapsed) and broken (bent) bones after animation.
class GoreMod extends SkeletonModifier3D:
	var skel: Skeleton3D
	var severed: Array = []
	var broken := {}

	func _process_modification() -> void:
		if skel == null:
			return
		for bi in severed:
			skel.set_bone_pose_scale(bi, Vector3(0.001, 0.001, 0.001))
		for bi in broken:
			skel.set_bone_pose_rotation(bi, skel.get_bone_pose_rotation(bi) * broken[bi])
