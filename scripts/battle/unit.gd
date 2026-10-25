extends Node3D
## A single combatant on the battlefield (soldier, hero, lord or the player).
## Movement and collisions are kinematic; the battle scene handles spatial
## queries, projectiles and bookkeeping.

const UnitVisual = preload("res://scripts/battle/unit_visual.gd")
const Looks = preload("res://scripts/actors/looks.gd")
const Bending = preload("res://scripts/battle/bending.gd")

const DIRS := ["left", "right", "overhead", "thrust"]

var battle
var team := 0
var troop_id := ""
var party_key := ""
var companion_id := ""
var lord_id := ""
var is_player := false
var display_name := ""
var is_hero := false

# Stats
var max_hp := 50.0
var hp := 50.0
var armor := 10.0
var skill := 0.4
var dmg_mult := 1.0
var weapon_id := "fists"
var weapon: Dictionary = {}
var ranged_id := ""
var ranged: Dictionary = {}
var ammo := 0
var shield := false
var bend := ""
var bend_power := 1.0
var bend_skill := 0
var chi := 100.0
var max_chi := 100.0
var chi_regen := 10.0
var healer := false
var chi_blocker := false
var mount_id := ""
var mount_hp := 0.0
var mount_max := 0.0
var mount_armor := 0.0
var foot_speed := 4.5
var mount_speed := 0.0
var radius := 0.4

# Runtime
var alive := true
var vel := Vector3.ZERO
var knock := Vector3.ZERO
var y_vel := 0.0
var airborne := false
var facing := 0.0
var action := ""
var action_t := 0.0
var action_total := 0.0
var attack_dir := "right"
var block_dir := "right"
var cooldowns := {}
var target = null
var retarget_t := 0.0
var think_t := 0.0
var order := "charge"
var hold_pos := Vector3.ZERO
var slow_t := 0.0
var burn_t := 0.0
var burn_dps := 0.0
var blind_t := 0.0
var bend_block_t := 0.0
var use_ranged := false
var parts := {}
var anim_t := 0.0
var fall_t := 0.0
var aim_point := Vector3.ZERO
var formation_offset := Vector3.ZERO
var last_attacker = null
var engaged_by := 0
var cast_anim := 0.0
var ally_marker: Node3D

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
func setup_troop(tid: String, p_team: int, key: String) -> void:
	var t: Dictionary = Data.troop(tid)
	troop_id = tid
	team = p_team
	party_key = key
	display_name = t.name
	is_hero = t.hero
	max_hp = t.hp
	armor = t.armor
	skill = t.skill / 100.0
	dmg_mult = 1.0 + t.tier * 0.06
	weapon_id = t.weapon
	ranged_id = t.ranged
	shield = t.shield
	bend = t.bend
	bend_power = t.bend_power
	healer = t.healer
	mount_id = t.mount
	foot_speed = 4.2 + t.tier * 0.15
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_finish_setup(Looks.troop_look(tid, rng))

func setup_lord(lid: String, p_team: int, key: String) -> void:
	var l: Dictionary = Data.lords[lid]
	lord_id = lid
	team = p_team
	party_key = key
	display_name = l.name
	is_hero = true
	max_hp = l.hp
	armor = 26
	skill = 0.85
	dmg_mult = 1.35
	weapon_id = l.weapon
	bend = l.bend
	bend_power = l.power
	mount_id = ""
	foot_speed = 5.0
	_finish_setup(Looks.lord_look(lid))

func setup_arena(f: Dictionary, p_team: int) -> void:
	team = p_team
	party_key = "arena"
	display_name = f.name
	is_hero = true
	max_hp = f.hp
	armor = f.armor
	skill = f.skill / 100.0
	dmg_mult = 1.2
	weapon_id = f.weapon
	bend = f.bend
	bend_power = f.power
	foot_speed = 4.8
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(f.name)
	var look := Looks.CB.random_look(f.get("culture", "earth"), rng, f.get("vlook", {}).get("sex", ""))
	look.merge(f.get("vlook", {}), true)
	look.merge({"outfit": "peasant", "kit": "sash"}, false)
	_finish_setup(look)

func setup_companion(cid: String, p_team: int) -> void:
	var c: Dictionary = Data.companions[cid]
	companion_id = cid
	team = p_team
	party_key = "player"
	display_name = c.name
	is_hero = true
	max_hp = c.hp
	armor = c.armor
	skill = c.skill / 100.0
	dmg_mult = 1.25
	weapon_id = c.weapon
	ranged_id = c.get("ranged", "")
	# Story outcomes can change a companion (Juro's fire returning, Hana's mastery)
	var cs: Dictionary = GS.companion_state(cid)
	bend = cs.get("bend", c.bend)
	bend_power = float(cs.get("power", c.power)) + float(cs.get("power_bonus", 0.0))
	healer = c.get("healer", false)
	chi_blocker = c.get("chi_blocker", false)
	mount_id = c.get("mount", "")
	foot_speed = 5.0
	_finish_setup(Looks.companion_look(cid))

func setup_player(p_team: int) -> void:
	var pl: Dictionary = GS.player
	is_player = true
	team = p_team
	party_key = "player"
	display_name = pl.name
	is_hero = true
	max_hp = GS.max_hp()
	armor = GS.player_armor()
	skill = clampf((pl.skills.weapon_mastery * 8 + pl.attrs.agi * 2) / 100.0 + 0.3, 0.3, 0.98)
	dmg_mult = 1.0 + pl.skills.power_strike * 0.08 + pl.attrs.str * 0.01
	weapon_id = pl.equip.get("weapon", "fists")
	if weapon_id == "":
		weapon_id = "fists"
	ranged_id = pl.equip.get("ranged", "")
	bend = pl.bend
	bend_skill = pl.skills.bending
	bend_power = 1.0 + bend_skill * 0.08 + pl.attrs.int * 0.01
	mount_id = pl.equip.get("mount", "")
	foot_speed = 5.0 * (1.0 + pl.skills.athletics * 0.03)
	_finish_setup(Looks.player_look())
	hp = clampf(float(pl.hp), max_hp * 0.25, max_hp)
	max_chi = GS.max_chi()
	chi = max_chi
	chi_regen = 9.0 + bend_skill * 1.2

func _finish_setup(look: Dictionary) -> void:
	hp = max_hp
	weapon = Data.item(weapon_id)
	if ranged_id != "":
		ranged = Data.item(ranged_id)
		ammo = ranged.ammo
	if mount_id != "":
		var m: Dictionary = Data.item(mount_id)
		mount_hp = m.hp
		mount_max = m.hp
		mount_armor = m.armor
		mount_speed = m.speed
		if is_player:
			mount_speed *= 1.0 + GS.player.skills.riding * 0.03
		radius = 0.9
	use_ranged = ranged_id != "" and not is_player
	parts = UnitVisual.build(self, look)

func add_ally_marker() -> void:
	var m := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.16, 0.16, 0.04)
	m.mesh = pm
	m.rotation_degrees.z = 180
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.4)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.material_override = mat
	m.position.y = 2.4 + float(parts.seat)
	add_child(m)
	ally_marker = m

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func mounted() -> bool:
	return mount_id != "" and mount_hp > 0.0

func speed() -> float:
	var s := mount_speed if mounted() else foot_speed
	if slow_t > 0.0:
		s *= 0.5
	if action in ["windup", "recover", "cast"] and not mounted():
		s *= 0.55
	if action == "block":
		s *= 0.6
	if action == "aim":
		s *= 0.5
	return s

func forward() -> Vector3:
	return Vector3(sin(facing), 0, cos(facing))

func flat_pos() -> Vector2:
	return Vector2(position.x, position.z)

func dist_to(u) -> float:
	return Vector2(position.x - u.position.x, position.z - u.position.z).length()

func chest() -> Vector3:
	return position + Vector3(0, 1.3 + float(parts.get("seat", 0.0)), 0)

func bend_mult() -> float:
	if bend == "":
		return 0.0
	match bend:
		"fire", "blue_fire": return battle.fire_mult
		"water": return battle.water_mult
	return 1.0

func can_bend(slot: String) -> bool:
	if bend == "" or bend_block_t > 0.0 or bend_mult() <= 0.01:
		return false
	var a := Bending.ability(bend, slot)
	if a.is_empty():
		return false
	if is_player and a.get("min_skill", 0) > bend_skill:
		return false
	return chi >= a.cost and cooldowns.get(slot, 0.0) <= 0.0

func melee_reach() -> float:
	return float(weapon.get("reach", 1.2)) + (0.8 if mounted() else 0.0)

func weapon_speed() -> float:
	return float(weapon.get("speed", 1.0)) * (0.85 + skill * 0.3)

# ---------------------------------------------------------------------------
# Per-frame update (called by battle)
# ---------------------------------------------------------------------------
func tick(delta: float) -> void:
	if not alive:
		_animate_death(delta)
		return
	# Timers
	for k in cooldowns.keys():
		cooldowns[k] = maxf(0.0, cooldowns[k] - delta)
	slow_t = maxf(0.0, slow_t - delta)
	blind_t = maxf(0.0, blind_t - delta)
	bend_block_t = maxf(0.0, bend_block_t - delta)
	cast_anim = maxf(0.0, cast_anim - delta)
	if burn_t > 0.0:
		burn_t -= delta
		apply_damage(burn_dps * delta, null, "fire", Vector3.ZERO, 0.0, true)
		if not alive:
			return
	if bend != "":
		chi = minf(max_chi, chi + chi_regen * delta)
	_update_action(delta)
	var desired := Vector3.ZERO
	if is_player and battle.player_controlled:
		desired = battle.player_move_vector() * speed()
	else:
		desired = _ai(delta)
	# Accelerate (mounts have momentum)
	var accel := 6.0 if mounted() else 18.0
	vel = vel.move_toward(desired, accel * delta)
	knock = knock.move_toward(Vector3.ZERO, 14.0 * delta)
	var move := (vel + knock) * delta
	var np := position + Vector3(move.x, 0, move.z)
	var pushed: Vector2 = battle.resolve_obstacles(Vector2(np.x, np.z), radius)
	np.x = clampf(pushed.x, -battle.HALF + 1.0, battle.HALF - 1.0)
	np.z = clampf(pushed.y, -battle.HALF + 1.0, battle.HALF - 1.0)
	var gh: float = battle.ground_height(np.x, np.z)
	if airborne:
		y_vel -= 18.0 * delta
		np.y = position.y + y_vel * delta
		if np.y <= gh:
			np.y = gh
			airborne = false
			y_vel = 0.0
	else:
		np.y = gh
	position = np
	# Facing
	if not is_player or not battle.player_controlled:
		var face_dir := Vector3.ZERO
		if target != null and is_instance_valid(target) and target.alive and dist_to(target) < 30.0 and (action != "" or dist_to(target) < 8.0 or use_ranged):
			face_dir = target.position - position
		elif vel.length() > 0.3:
			face_dir = vel
		if face_dir.length() > 0.01:
			var want := atan2(face_dir.x, face_dir.z)
			facing = lerp_angle(facing, want, minf(1.0, delta * (4.0 if mounted() else 9.0)))
	rotation.y = facing
	_animate(delta)

func jump() -> void:
	if not airborne and not mounted():
		airborne = true
		y_vel = 6.5
		parts.actor.action("ual1/Jump_Start", 1.2, true)

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------
func _set_action(a: String, t: float) -> void:
	action = a
	action_t = t
	action_total = t

func _update_action(delta: float) -> void:
	if action == "":
		return
	action_t -= delta
	match action:
		"windup":
			if action_t <= 0.0:
				battle.melee_strike(self)
				_set_action("recover", 0.38 / weapon_speed())
		"aim":
			pass  # held until release
		_:
			if action_t <= 0.0:
				action = ""

func start_attack(dir: String = "") -> bool:
	if action != "" and action != "block":
		return false
	if dir == "":
		dir = DIRS[randi() % 4]
		if mounted():
			dir = ["left", "right", "thrust"].pick_random()
	attack_dir = dir
	var windup := 0.42 / weapon_speed()
	_set_action("windup", windup)
	UnitVisual.attack(self, dir, windup + 0.38 / weapon_speed())
	Sfx.play_at("swing", position, -10.0)
	battle.on_attack_started(self, windup)
	return true

func start_block(dir: String = "") -> void:
	if action in ["windup", "stagger", "cast"]:
		return
	block_dir = dir if dir != "" else attack_dir
	_set_action("block", 99.0)
	parts.actor.action("ual2/Sword_Block", 1.2)

func stop_block() -> void:
	if action == "block":
		action = ""

func start_aim() -> bool:
	if ranged.is_empty() or ammo <= 0:
		return false
	if action != "" and action != "block":
		return false
	_set_action("aim", 99.0)
	action_total = 0.0
	parts.actor.action("ual1/Spell_Simple_Enter", 1.0)
	return true

## Release a drawn ranged weapon towards a point. Returns true if fired.
func release_aim(point: Vector3) -> bool:
	if action != "aim":
		return false
	var drawn := 99.0 - action_t
	action = ""
	if drawn < 0.35 or ammo <= 0:
		return false
	ammo -= 1
	var acc: float = float(ranged.accuracy) * (0.55 + skill * 0.45)
	if blind_t > 0.0:
		acc *= 0.4
	if is_player:
		acc = clampf(0.85 + GS.player.skills.archery * 0.03, 0.85, 1.0)
	var from := chest() + forward() * 0.5
	var dist := from.distance_to(point)
	var spread := (1.0 - acc) * 0.35 * clampf(dist / 20.0, 0.4, 2.5)
	var dir := (point - from).normalized()
	dir = (dir + Vector3(randf_range(-spread, spread), randf_range(-spread, spread) * 0.6, randf_range(-spread, spread))).normalized()
	var spd: float = ranged.proj_speed
	var grav := 4.0 if ranged.model == "bow" else 2.0
	# compensate for drop
	var t := dist / spd
	dir.y += grav * t * 0.5 / spd
	dir = dir.normalized()
	var d: float = ranged.dmg * (1.0 + (GS.player.skills.archery * 0.08 if is_player else skill * 0.25))
	battle.spawn_projectile({
		"owner_unit": self, "team": team, "vel": dir * spd, "gravity": grav, "dmg": d,
		"dtype": "pierce" if ranged.model != "boomerang" else "blunt", "radius": 0.15,
		"knock": 1.0, "fx": "arrow" if ranged.model == "bow" else ranged.model, "life": 4.0,
	}, from)
	Sfx.play_at("bow", position, -6.0)
	parts.actor.action("ual2/OverhandThrow" if ranged.model != "bow" else "ual1/Spell_Simple_Shoot", 1.6)
	return true

## Use a bending ability towards a world point.
func cast(slot: String, point: Vector3) -> bool:
	if not can_bend(slot):
		return false
	if action in ["windup", "stagger", "aim"]:
		return false
	var a := Bending.ability(bend, slot)
	chi -= a.cost
	cooldowns[slot] = a.cd
	_set_action("cast", 0.3)
	cast_anim = 0.35
	UnitVisual.cast(self, slot)
	battle.execute_bending(self, a, point)
	return true

# ---------------------------------------------------------------------------
# Damage
# ---------------------------------------------------------------------------
## Returns true if the hit landed (false if blocked).
func receive_melee(attacker, dmg: float, dtype: String, dir: String) -> bool:
	if not alive:
		return false
	var to_attacker: Vector3 = (attacker.position - position)
	to_attacker.y = 0
	var facing_attacker := forward().dot(to_attacker.normalized()) > 0.25
	if action == "block" and facing_attacker:
		var ok := false
		if is_player:
			ok = GS.settings.auto_block or block_dir == dir or (shield and dir != "overhead")
		else:
			ok = randf() < clampf(0.55 + skill * 0.35 + (0.2 if shield else 0.0), 0.0, 0.97)
		if ok:
			Sfx.play_at("block", position, -4.0)
			battle.spawn_spark(chest() + forward() * 0.4)
			attacker._set_action("stagger", 0.35)
			if is_player:
				battle.hud_note("Blocked!")
			return false
	var push: Vector3 = -to_attacker.normalized()
	apply_damage(dmg, attacker, dtype, push, 2.0 + (4.0 if attacker.mounted() else 0.0))
	if attacker.chi_blocker and bend != "":
		bend_block_t = 8.0
		if is_player:
			battle.hud_note("Your chi has been blocked!")
	return true

func apply_damage(amount: float, attacker, dtype: String, push: Vector3, knockback: float, ignore_armor: bool = false) -> void:
	if not alive:
		return
	var a := 0.0 if ignore_armor else armor
	if dtype == "blunt":
		a *= 0.6
	var dmg := maxf(amount * 0.25, amount - a * 0.42) if amount > 0.0 else 0.0
	if is_player:
		dmg *= [0.5, 1.0, 1.5][clampi(int(GS.settings.difficulty), 0, 2)]
	# Mounts soak some hits
	if mounted() and randf() < 0.4 and not ignore_armor:
		mount_hp -= maxf(amount * 0.3, amount - mount_armor * 0.5)
		if mount_hp <= 0.0:
			_dismount()
		return
	hp -= dmg
	if attacker != null:
		last_attacker = attacker
	if push != Vector3.ZERO:
		knock += push * knockback
	if dmg >= 6.0 and not ignore_armor:
		if action == "windup" or action == "cast" or action == "aim":
			action = ""
		if not mounted():
			_set_action("stagger", 0.25)
		UnitVisual.hit(self, knockback > 6.0)
		Sfx.play_at("hit", position, -5.0)
	if hp <= 0.0:
		die(attacker, dtype)

func heal(amount: float) -> void:
	if alive:
		hp = minf(max_hp, hp + amount)

func _dismount() -> void:
	mount_hp = 0.0
	radius = 0.4
	if parts.has("mount"):
		var m: Node3D = parts.mount
		var anim: AnimationPlayer = parts.mount_rig.anim if parts.has("mount_rig") else null
		var dn: String = load("res://scripts/actors/mount.gd").death_anim(parts.mount_rig) if parts.has("mount_rig") else ""
		if anim != null and anim.has_animation(dn):
			anim.get_animation(dn).loop_mode = Animation.LOOP_NONE
			anim.play(dn, 0.15)
			anim.speed_scale = 1.0
			parts.erase("mount_rig")
		else:
			var tw := m.create_tween()
			tw.tween_property(m, "rotation_degrees:z", 90.0, 0.5)
	parts.seat = 0.0
	parts.actor.position.y = 0.0
	parts.actor.set_stance("unarmed")
	if is_player:
		battle.hud_note("Your mount has fallen!")

func die(killer, dtype: String) -> void:
	if not alive:
		return
	alive = false
	hp = 0.0
	action = "dead"
	fall_t = 0.0
	if ally_marker:
		ally_marker.visible = false
	if parts.has("glow"):
		parts.glow.visible = false
	parts.actor.die()
	Sfx.play_at("death", position, -4.0)
	battle.on_unit_down(self, killer, dtype)

func _animate_death(delta: float) -> void:
	if fall_t < 1.0:
		fall_t = minf(1.0, fall_t + delta * 2.5)
		if parts.has("mount") and mount_hp > 0.0:
			parts.mount.rotation_degrees.z = lerpf(0.0, 85.0, fall_t)
			parts.actor.position.y = lerpf(float(parts.seat) + 0.4, 0.0, fall_t)

# ---------------------------------------------------------------------------
# AI
# ---------------------------------------------------------------------------
func _ai(delta: float) -> Vector3:
	if action in ["stagger", "cast"]:
		return Vector3.ZERO
	retarget_t -= delta
	think_t -= delta
	if target == null or not is_instance_valid(target) or not target.alive or retarget_t <= 0.0:
		target = battle.find_target(self)
		retarget_t = randf_range(0.5, 1.0)
	# Order handling
	var order_pos := Vector3.INF
	var engage_radius := INF
	match order:
		"hold":
			order_pos = hold_pos
			engage_radius = 7.0 if not use_ranged else 70.0
		"follow":
			var pu = battle.player_unit
			if pu != null and pu.alive:
				order_pos = pu.position + formation_offset
				engage_radius = 9.0
	if target == null:
		if order_pos != Vector3.INF:
			return _move_towards(order_pos, 1.5)
		return Vector3.ZERO
	var dist := dist_to(target)
	if dist > engage_radius and not (use_ranged and ammo > 0 and dist < 70.0 and order == "hold"):
		if order_pos != Vector3.INF:
			return _move_towards(order_pos, 1.5)
	# Healers look after allies first
	if healer and can_bend("e"):
		var hurt = battle.hurt_ally_near(self, 6.0)
		if hurt != null:
			cast("e", hurt.position)
			return Vector3.ZERO
	# Bending
	if bend != "" and bend_mult() > 0.01 and bend_block_t <= 0.0:
		var bv := _ai_bend(dist)
		if bv != Vector3.INF:
			return bv
	# Ranged weapons
	if use_ranged and ranged_id != "" and ammo > 0 and dist > 5.0 and dist < 65.0:
		if action == "aim":
			if 99.0 - action_t > 1.3 - skill * 0.5:
				release_aim(battle.lead_point(self, target, float(ranged.proj_speed)))
			return Vector3.ZERO
		if action == "" and think_t <= 0.0:
			start_aim()
			think_t = randf_range(0.2, 0.6)
		if order == "hold" or not mounted():
			return Vector3.ZERO
	if action == "aim":
		action = ""
	return _ai_melee(dist, delta)

func _ai_bend(dist: float) -> Vector3:
	var q := Bending.ability(bend, "q")
	var rng: float = q.get("range", 20.0)
	# Specials
	if can_bend("r") and (is_hero or bend_power >= 1.6) and randf() < 0.02:
		var r := Bending.ability(bend, "r")
		# Only great masters (lords and heroes) can generate lightning
		if r.kind == "lightning" and is_hero and lord_id != "" and bend_power >= 2.5 and dist < r.range and dist > 6.0:
			cast("r", target.chest())
			return Vector3.ZERO
		if r.kind == "quake" and battle.enemies_near(self, r.range) >= 3:
			cast("r", position)
			return Vector3.ZERO
		if r.kind == "volley" and dist < r.range:
			cast("r", target.chest())
			return Vector3.ZERO
	if dist < 5.0 and can_bend("e"):
		var e := Bending.ability(bend, "e")
		if e.kind == "cone":
			cast("e", target.position)
			return Vector3.ZERO
	if can_bend("q") and dist < rng * 0.95 and dist > 2.0 and think_t <= 0.0:
		think_t = randf_range(0.15, 0.6) * (1.3 - skill)
		cast("q", battle.lead_point(self, target, float(q.get("speed", 30.0))))
		return Vector3.ZERO
	# Keep at casting distance while chi recovers
	if chi >= q.get("cost", 10.0) and dist > 4.5:
		if dist > rng * 0.8:
			return _move_towards(target.position, 0.0)
		return Vector3.ZERO
	return Vector3.INF

func _ai_melee(dist: float, _delta: float) -> Vector3:
	var reach = melee_reach() + target.radius
	if mounted():
		# Cavalry charge through the target and wheel around
		if dist < reach and action == "" and think_t <= 0.0:
			start_attack()
			think_t = randf_range(0.6, 1.2)
		var through: Vector3 = target.position + (target.position - position).normalized() * 6.0
		return _move_towards(through, 0.0)
	if dist <= reach * 0.95:
		if action == "" and think_t <= 0.0:
			start_attack()
			think_t = randf_range(0.15, 0.6) * (1.4 - skill)
		# Small circling to avoid perfect stacking
		var side := Vector3(-forward().z, 0, forward().x) * (0.6 if (get_instance_id() % 2 == 0) else -0.6)
		return side
	return _move_towards(target.position, reach * 0.8)

func _move_towards(p: Vector3, stop_dist: float) -> Vector3:
	var waypoint: Vector3 = battle.path_point(position, p)
	var d := Vector3(waypoint.x - position.x, 0, waypoint.z - position.z)
	var l := d.length()
	if l <= stop_dist:
		return Vector3.ZERO
	return d / l * speed()

## Called when an enemy starts an attack against this unit (AI decides to block).
func incoming_attack(attacker, windup: float) -> void:
	if is_player and battle.player_controlled:
		return
	if not alive or action in ["windup", "cast", "aim", "stagger"]:
		return
	var p := 0.25 + skill * 0.55 + (0.15 if shield else 0.0)
	if randf() < p:
		_set_action("block", windup + 0.25)
		block_dir = attacker.attack_dir

# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------
func _animate(delta: float) -> void:
	UnitVisual.animate(self, delta)
