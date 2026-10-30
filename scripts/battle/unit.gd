extends Node3D
## A single combatant on the battlefield (soldier, hero, lord or the player).
## Movement and collisions are kinematic; the battle scene handles spatial
## queries, projectiles and bookkeeping.

const UnitVisual = preload("res://scripts/battle/unit_visual.gd")
const Forms = preload("res://scripts/battle/forms.gd")
const Looks = preload("res://scripts/actors/looks.gd")
const Bending = preload("res://scripts/battle/bending.gd")
const AvatarSys = preload("res://scripts/core/avatar.gd")
const Techniques = preload("res://scripts/battle/techniques.gd")
const Gore = preload("res://scripts/battle/gore.gd")

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
# The Avatar bends every element they have mastered, and once per battle may
# enter the Avatar State (scripts/core/avatar.gd)
var avatar_elements: Array = []
var avatar_rot_t := 0.0
var avatar_state_t := 0.0
var avatar_state_used := false
var avatar_state_able := true
# Expansion techniques: slot -> technique id (player and companions), and a
# timed buff stance (power, armour, damage reduction, speed, sight)
var loadout: Dictionary = {}
var buff: Dictionary = {}
var buff_t := 0.0
var root_t := 0.0
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
# A bending form in progress: movements still to play, then the release
var form_seq: Array = []
var form_step_t := 0.0
var form_release_t := -1.0
var form_ability: Dictionary = {}
var target = null
var retarget_t := 0.0
var think_t := 0.0
var order := "charge"
var hold_pos := Vector3.ZERO
var slow_t := 0.0
var burn_t := 0.0
var burn_dps := 0.0
## Soaked by water or rain: burns briefly, conducts lightning.
var wet_t := 0.0
## What is hurting this unit right now, for how its death looks (gore.gd):
## "blade", "water_slice", "impale", "fall", "fire" or "".
var gore_hint := ""
## Height held above the ground (the Avatar risen in the Avatar State).
var levitate := 0.0
var char_amt := 0.0
var _fall_v := 0.0
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
	chi_blocker = t.get("chi_blocker", false)
	mount_id = t.mount
	foot_speed = 4.2 + t.tier * 0.15
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if tid == "avatar":
		_make_avatar()
		_finish_setup(AvatarSys.look())
		return
	_finish_setup(Looks.troop_look(tid, rng))

## Stage of life decides the Avatar's strength and control of the Avatar State.
func _make_avatar() -> void:
	var st: String = AvatarSys.stage()
	display_name = AvatarSys.display_name().capitalize()
	is_hero = true
	max_hp = {"young": 380.0, "prime": 650.0, "elder": 480.0}.get(st, 450.0)
	armor = 20.0
	bend_power = {"young": 2.2, "prime": 3.2, "elder": 2.9}.get(st, 2.6)
	skill = {"young": 0.8, "prime": 0.97, "elder": 0.92}.get(st, 0.9)
	dmg_mult = 1.4
	foot_speed = {"young": 5.6, "prime": 5.4, "elder": 4.2}.get(st, 5.0)
	_set_avatar_elements(AvatarSys.elements())
	# A young Avatar cannot yet call the Avatar State at will
	avatar_state_able = st != "young" or randf() < 0.5

func _set_avatar_elements(els: Array) -> void:
	avatar_elements = els.duplicate()
	if avatar_elements.is_empty():
		avatar_elements = ["air"]
	bend = avatar_elements[0]

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
	if bend == "avatar":
		_set_avatar_elements(AvatarSys.elements())
		avatar_state_able = false
	loadout = c.get("techs", {}).duplicate()
	loadout.merge(cs.get("loadout", {}), true)
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
	skill = clampf((GS.skill("weapon_mastery") * 8 + GS.attr("dex") * 2) / 100.0 + 0.3, 0.3, 0.98)
	dmg_mult = 1.0 + GS.skill("power_strike") * 0.08 + GS.attr("str") * 0.01
	weapon_id = pl.equip.get("weapon", "fists")
	if weapon_id == "":
		weapon_id = "fists"
	if pl.get("tempered", "") == weapon_id and weapon_id != "fists":
		dmg_mult *= 1.12   # tempered in bending-fire (Embers of the First Flame)
	ranged_id = pl.equip.get("ranged", "")
	bend = pl.bend
	loadout = pl.get("loadout", {}).duplicate()
	bend_skill = GS.skill("bending")
	bend_power = 1.0 + bend_skill * 0.08 + GS.attr("att") * 0.01
	mount_id = pl.equip.get("mount", "")
	foot_speed = 5.0 * (1.0 + GS.skill("athletics") * 0.03)
	_finish_setup(Looks.player_look())
	hp = clampf(float(pl.hp), max_hp * 0.25, max_hp)
	max_chi = GS.max_chi()
	chi = max_chi
	chi_regen = 9.0 + bend_skill * 1.2

func _finish_setup(look: Dictionary) -> void:
	hp = max_hp
	# Nobody acts on the first frame: a moment to read the field.
	think_t = randf_range(0.5, 1.5)
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
			mount_speed *= 1.0 + GS.skill("riding") * 0.03
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
	if root_t > 0.0:
		return 0.0
	var s := mount_speed if mounted() else foot_speed
	if slow_t > 0.0:
		s *= 0.5
	s *= float(buff_val("speed", 1.0))
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

## The ability on a slot: a learned technique if one is set and fits the
## current element, otherwise the art's basic ability.
func ability_for(slot: String) -> Dictionary:
	if not loadout.is_empty() and avatar_elements.is_empty():
		var a := Techniques.loadout_ability(loadout, slot)
		if not a.is_empty() and Techniques.get_tech(loadout[slot]).element == Forms.art_of(bend):
			return a
	if slot == "r" and lord_id != "" and Data.lords.get(lord_id, {}).get("lightning", false):
		return Bending.LIGHTNING
	return Bending.ability(bend, slot)

func buff_val(key: String, default):
	return buff.get(key, default) if buff_t > 0.0 else default

func start_buff(a: Dictionary) -> void:
	buff = a.duplicate()
	buff_t = float(a.get("dur", 8.0))
	if parts.has("glow"):
		parts.glow.visible = true

func can_bend(slot: String) -> bool:
	if bend == "" or bend_block_t > 0.0 or bend_mult() <= 0.01:
		return false
	var a := ability_for(slot)
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
	root_t = maxf(0.0, root_t - delta)
	if buff_t > 0.0:
		buff_t -= delta
		if buff.get("sight", false):
			blind_t = 0.0
		if buff_t <= 0.0 and parts.has("glow") and cast_anim <= 0.0:
			parts.glow.visible = false
	bend_block_t = maxf(0.0, bend_block_t - delta)
	cast_anim = maxf(0.0, cast_anim - delta)
	wet_t = maxf(0.0, wet_t - delta)
	if battle.field != null and battle.field.rain:
		wet_t = maxf(wet_t, 1.0)
	if burn_t > 0.0:
		if wet_t > 0.0:
			burn_t = minf(burn_t, 0.4)
		burn_t -= delta
		gore_hint = "fire"
		# burning alive: the body blackens as it burns
		char_amt = minf(1.0, char_amt + delta * 0.09 * burn_dps / 3.0)
		if Gore.enabled() and char_amt > 0.05:
			Gore.char_body(self, char_amt)
		apply_damage(burn_dps * delta, null, "fire", Vector3.ZERO, 0.0, true)
		if not alive:
			return
		# a burning soldier running through dry grass sets it alight
		if battle.field != null and randf() < delta * 0.25:
			battle.field.ignite(position, 0.5, 0.6)
	if bend != "":
		chi = minf(max_chi, chi + chi_regen * delta * float(buff_val("regen", 1.0)))
	if not avatar_elements.is_empty():
		_update_avatar(delta)
	_update_action(delta)
	_update_form(delta)
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
			var impact := -y_vel
			y_vel = 0.0
			_hard_landing(impact)
	else:
		np.y = gh + levitate
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
		acc = clampf(0.85 + GS.skill("archery") * 0.03, 0.85, 1.0)
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
	var d: float = ranged.dmg * (1.0 + (GS.skill("archery") * 0.08 if is_player else skill * 0.25))
	battle.spawn_projectile({
		"owner_unit": self, "team": team, "vel": dir * spd, "gravity": grav, "dmg": d,
		"dtype": "pierce" if ranged.model != "boomerang" else "blunt", "radius": 0.15,
		"knock": 1.0, "fx": "arrow" if ranged.model == "bow" else ranged.model, "life": 4.0,
	}, from)
	Sfx.play_at("bow", position, -6.0)
	parts.actor.action("ual2/OverhandThrow" if ranged.model != "bow" else "ual1/Spell_Simple_Shoot", 1.6)
	return true

## Use a bending ability towards a world point.
## Perform a designed form: each movement plays in turn (with its stance
## emphasis), then the element is released.
func cast_form(form: Dictionary) -> String:
	if bend == "" or bend_block_t > 0.0 or bend_mult() <= 0.01:
		return "You cannot bend right now."
	if not form_seq.is_empty() or action in ["windup", "stagger", "aim"]:
		return "busy"
	var ev := Forms.evaluate(form)
	if not ev.valid:
		return "That form is not valid: " + ", ".join(ev.errors)
	if chi < ev.ability.cost:
		return "Not enough chi for %s." % form.get("name", "the form")
	if cooldowns.get("f", 0.0) > 0.0:
		return "busy"
	chi -= ev.ability.cost
	cooldowns["f"] = ev.ability.cd + ev.windup
	form_ability = ev.ability
	form_seq = []
	for id in form.moves:
		form_seq.append(Forms.move(form.art, id))
	form_step_t = 0.0
	form_release_t = -1.0
	_set_action("cast", ev.windup + 0.2)
	if parts.actor.bend_pose:
		parts.actor.bend_pose.set_form(Forms.art_of(bend))
	form["uses"] = int(form.get("uses", 0)) + 1
	return ""

func _update_form(delta: float) -> void:
	if form_release_t >= 0.0:
		form_release_t -= delta
		if form_release_t < 0.0:
			var point: Vector3 = battle.aim_point() if is_player and battle.player_controlled else (target.chest() if target != null and is_instance_valid(target) else position + forward() * 10.0)
			cast_anim = 0.35
			battle.execute_bending(self, form_ability, point)
		return
	if form_seq.is_empty():
		return
	form_step_t -= delta
	if form_step_t > 0.0:
		return
	var m: Dictionary = form_seq.pop_front()
	var a = parts.actor
	var clip_len: float = a.action_length(m.anim)
	var full: bool = m.anim in ["ual2/NinjaJump_Land", "ual1/Jump_Land", "ual1/Roll"]
	a.action(m.anim, clampf(clip_len / maxf(0.2, m.dur), 0.6, 3.0), full)
	if m.pulse != "" and a.bend_pose:
		a.bend_pose.pulse(m.pulse)
	form_step_t = m.dur
	if form_seq.is_empty():
		form_release_t = m.dur * 0.6

func cast(slot: String, point: Vector3) -> bool:
	if not can_bend(slot):
		return false
	if action in ["windup", "stagger", "aim"]:
		return false
	var a := ability_for(slot)
	chi -= a.cost
	cooldowns[slot] = a.cd
	_set_action("cast", 0.3)
	cast_anim = 0.35
	UnitVisual.cast(self, slot)
	if not avatar_elements.is_empty():
		var c: Dictionary = get_meta("casts", {})
		c[bend] = int(c.get(bend, 0)) + 1
		set_meta("casts", c)
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

## The Avatar rotates through their elements; at the edge of defeat the past
## lives answer once: the Avatar State.
func _update_avatar(delta: float) -> void:
	avatar_rot_t -= delta
	if avatar_rot_t <= 0.0 and action == "":
		bend = avatar_elements.pick_random()
		avatar_rot_t = randf_range(2.5, 5.0)
	if avatar_state_t > 0.0:
		avatar_state_t -= delta
		for k in cooldowns.keys():
			cooldowns[k] = maxf(0.0, cooldowns[k] - delta * 1.5)
		chi = max_chi
		if avatar_state_t <= 0.0:
			bend_power /= 1.5
			UnitVisual.avatar_glow(self, false)
	elif not avatar_state_used and avatar_state_able and hp < max_hp * 0.35 and alive:
		enter_avatar_state()

## The past lives answer: ten seconds of the Avatar State.
func enter_avatar_state(duration: float = 10.0) -> void:
	if avatar_state_used or not alive:
		return
	if true:
		avatar_state_used = true
		avatar_state_t = duration
		hp = minf(max_hp, hp + max_hp * 0.25)
		bend_power *= 1.5
		UnitVisual.avatar_glow(self, true)
		if battle != null and battle.has_method("avatar_state"):
			battle.avatar_state(self)

func apply_damage(amount: float, attacker, dtype: String, push: Vector3, knockback: float, ignore_armor: bool = false) -> void:
	if not alive:
		return
	if avatar_state_t > 0.0:
		amount *= 0.4
		knockback *= 0.2
	if buff_t > 0.0:
		amount *= 1.0 - float(buff.get("reduce", 0.0))
		if buff.get("knock_immune", false):
			knockback = 0.0
	var a := 0.0 if ignore_armor else armor + float(buff_val("armor", 0.0))
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
	Gore.on_death(battle, self, dtype, gore_hint)
	Sfx.play_at("death", position, -4.0)
	battle.on_unit_down(self, killer, dtype)

## Thrown high and coming down hard: bones break. The living limp.
func _hard_landing(impact: float) -> void:
	if impact < 11.0:
		return
	gore_hint = "fall"
	apply_damage((impact - 11.0) * 7.0, last_attacker, "blunt", Vector3.ZERO, 0.0, true)
	if alive and impact > 13.0 and Gore.enabled():
		Gore.break_limb(self, ["shin_l", "shin_r", "forearm_l", "forearm_r"].pick_random())
		slow_t = 30.0
		if is_player:
			battle.hud_note("You land badly. Something breaks.")

func _animate_death(delta: float) -> void:
	# a body killed in the air still falls, and breaks when it lands
	var gh: float = battle.ground_height(position.x, position.z)
	if position.y > gh + 0.02:
		_fall_v -= 18.0 * delta
		position.y = maxf(gh, position.y + _fall_v * delta)
		if position.y <= gh and -_fall_v > 11.0 and Gore.enabled():
			Gore.break_limb(self, ["shin_l", "shin_r", "forearm_l", "forearm_r"].pick_random())
			Gore.bleed(battle, self, 0.6)
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
	if battle.opening_t > 0.0:
		return Vector3.ZERO
	# burning alive, they run and flail
	if burn_t > 0.0 and char_amt > 0.15 and Gore.enabled():
		if randf() < delta * 2.0 or vel.length() < 0.5:
			var a := randf() * TAU
			return Vector3(cos(a), 0, sin(a)) * speed() * 1.2
		return vel.normalized() * speed() * 1.2
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
	if healer and can_bend("e") and ability_for("e").get("kind", "") == "heal":
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
	var q := ability_for("q")
	var rng: float = q.get("range", 20.0)
	# Specials
	if can_bend("r") and (is_hero or bend_power >= 1.6) and randf() < 0.02:
		var r := ability_for("r")
		# Lightning: only the two royals who can make it
		if r.kind == "lightning" and dist < r.range and dist > 6.0:
			cast("r", target.chest())
			return Vector3.ZERO
		if r.kind in ["quake", "nova"] and battle.enemies_near(self, r.range) >= 3:
			cast("r", position)
			return Vector3.ZERO
		if r.kind in ["volley", "line", "projectile"] and dist < r.get("range", 20.0):
			cast("r", target.chest() + _aim_error(dist))
			return Vector3.ZERO
		if r.kind == "buff" and (hp < max_hp * 0.6 or battle.enemies_near(self, 6.0) >= 2):
			cast("r", position)
			return Vector3.ZERO
	var e := ability_for("e")
	if can_bend("e") and not e.is_empty():
		match e.kind:
			"cone":
				if dist < float(e.get("range", 6.0)) * 0.9:
					cast("e", target.position)
					return Vector3.ZERO
			"nova":
				if battle.enemies_near(self, e.range) >= 2:
					cast("e", position)
					return Vector3.ZERO
			"dash":
				if dist > 4.0 and dist < float(e.dist) and randf() < 0.3:
					cast("e", target.position)
					return Vector3.ZERO
			"line", "projectile":
				if dist < float(e.get("range", 20.0)) * 0.9 and randf() < 0.25:
					cast("e", target.chest() + _aim_error(dist))
					return Vector3.ZERO
			"buff":
				if hp < max_hp * 0.7 and randf() < 0.2:
					cast("e", position)
					return Vector3.ZERO
	if can_bend("q") and dist < rng * 0.95 and dist > 2.0 and think_t <= 0.0:
		# A breath between throws: benders do not fire the instant chi allows.
		think_t = randf_range(0.4, 1.0) * (1.4 - skill)
		if q.kind in ["cone", "nova", "buff"]:
			if dist < rng * 0.9:
				cast("q", target.position)
				return Vector3.ZERO
		else:
			cast("q", battle.lead_point(self, target, float(q.get("speed", 30.0))) + _aim_error(dist))
			return Vector3.ZERO
	# Keep at casting distance while chi recovers
	if chi >= q.get("cost", 10.0) and dist > 4.5:
		if dist > rng * 0.8:
			return _move_towards(target.position, 0.0)
		return Vector3.ZERO
	return Vector3.INF

## Where an AI bender's shot drifts from a perfect lead: wider at range, and
## for less skilled benders.
func _aim_error(dist: float) -> Vector3:
	var spread := dist * 0.07 * (1.25 - skill)
	return Vector3(randf_range(-spread, spread), randf_range(-spread, spread) * 0.5, randf_range(-spread, spread))

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
