extends RefCounted
## Bridges battle units to the rigged Actor: builds the character (culture
## outfit, headwear, garments), weapons in the hands, an optional mount, and
## maps combat events to animations, bending stances and facial expressions.

const Actor = preload("res://scripts/actors/actor.gd")
const Acc = preload("res://scripts/actors/accessories.gd")
const CB = preload("res://scripts/actors/character_builder.gd")
const UnitModel = preload("res://scripts/battle/unit_model.gd")
const Mount = preload("res://scripts/actors/mount.gd")

const Looks = preload("res://scripts/actors/looks.gd")

# ---------------------------------------------------------------------------
# Weapon meshes (blade along +Z, grip at the origin)
# ---------------------------------------------------------------------------
static func _blade(length: float, width: float, thick: float, curve: float, c: Color, tip: float = 0.12) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 10
	var pts := []
	for i in segs + 1:
		var z := length * i / segs
		var w := width * (1.0 if z < length - tip else (length - z) / tip)
		var y := curve * pow(z / length, 2.0)
		pts.append([Vector3(0, y + w * 0.5, z), Vector3(0, y - w * 0.5, z), Vector3(thick, y, z), Vector3(-thick, y, z)])
	for i in segs:
		var a: Array = pts[i]
		var b: Array = pts[i + 1]
		for f in [[0, 2], [2, 1], [1, 3], [3, 0]]:
			var p0: Vector3 = a[f[0]]
			var p1: Vector3 = a[f[1]]
			var p2: Vector3 = b[f[0]]
			var p3: Vector3 = b[f[1]]
			for p in [p0, p2, p1, p1, p2, p3]:
				st.add_vertex(p)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = Acc.mat(c, true, 0.4, true)
	return mi

static func _rod(length: float, r: float, c: Color, z0: float = 0.0) -> MeshInstance3D:
	return Acc.node(Acc.lathe([Vector2(r, 0.0), Vector2(r, length)], 8), c, Acc.at(Vector3(0, 0, z0), Vector3(90, 0, 0)))

static func weapon(model: String, trim: Color) -> Node3D:
	var n := Node3D.new()
	var steel := Color(0.82, 0.85, 0.9)
	var wood := Color(0.42, 0.28, 0.15)
	match model:
		"sword", "space_sword":
			n.add_child(_rod(0.18, 0.014, Color(0.2, 0.12, 0.08), -0.1))
			n.add_child(Acc.torus(0.02, 0.045, trim, Acc.at(Vector3(0, 0, 0.08), Vector3(0, 0, 0), Vector3(1, 0.4, 0.4))))
			var b := _blade(0.78, 0.035, 0.006, 0.0, steel if model == "sword" else Color(0.12, 0.12, 0.16), 0.08)
			b.position.z = 0.09
			n.add_child(b)
		"dao", "dual_dao", "machete":
			n.add_child(_rod(0.17, 0.015, Color(0.2, 0.12, 0.08), -0.1))
			n.add_child(Acc.torus(0.02, 0.05, trim, Acc.at(Vector3(0, 0, 0.07), Vector3.ZERO, Vector3(1, 0.4, 0.4))))
			var b2 := _blade(0.62 if model != "machete" else 0.48, 0.07, 0.006, 0.06, steel, 0.16)
			b2.position.z = 0.08
			n.add_child(b2)
		"hooks":
			n.add_child(_rod(0.15, 0.014, wood, -0.12))
			var b3 := _blade(0.7, 0.03, 0.006, 0.0, steel, 0.05)
			b3.position.z = 0.03
			n.add_child(b3)
			n.add_child(Acc.torus(0.06, 0.075, steel, Acc.at(Vector3(0, 0.06, 0.73), Vector3(0, 90, 0), Vector3(1, 1, 0.3))))
		"spear":
			n.add_child(_rod(2.1, 0.018, wood, -0.6))
			var b4 := _blade(0.25, 0.06, 0.008, 0.0, steel, 0.18)
			b4.position.z = 1.5
			n.add_child(b4)
			n.add_child(Acc.torus(0.015, 0.04, Color(0.7, 0.1, 0.08), Acc.at(Vector3(0, 0, 1.48), Vector3(90, 0, 0))))
		"guan_dao":
			n.add_child(_rod(2.1, 0.02, wood, -0.6))
			var b5 := _blade(0.5, 0.13, 0.008, 0.08, steel, 0.2)
			b5.position.z = 1.45
			n.add_child(b5)
		"staff":
			n.add_child(_rod(1.9, 0.02, wood, -0.6))
		"club":
			n.add_child(Acc.node(Acc.lathe([Vector2(0.018, 0.0), Vector2(0.03, 0.4), Vector2(0.045, 0.55), Vector2(0.0, 0.62)], 10), Color(0.9, 0.87, 0.78), Acc.at(Vector3(0, 0, -0.08), Vector3(90, 0, 0))))
		"axe":
			n.add_child(_rod(0.75, 0.016, wood, -0.12))
			var b6 := _blade(0.16, 0.18, 0.008, 0.0, steel, 0.03)
			b6.rotation_degrees = Vector3(0, 0, 90)
			b6.position = Vector3(0, 0.06, 0.48)
			n.add_child(b6)
		"knife":
			var b7 := _blade(0.24, 0.03, 0.005, 0.0, steel, 0.06)
			b7.position.z = 0.03
			n.add_child(b7)
		"fans":
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in 12:
				var a0 := deg_to_rad(-80 + 160.0 * i / 12)
				var a1 := deg_to_rad(-80 + 160.0 * (i + 1) / 12)
				for p in [Vector3.ZERO, Vector3(0, sin(a0) * 0.28, cos(a0) * 0.28), Vector3(0, sin(a1) * 0.28, cos(a1) * 0.28)]:
					st.set_normal(Vector3.RIGHT)
					st.add_vertex(p)
			var f := MeshInstance3D.new()
			f.mesh = st.commit()
			f.material_override = Acc.mat(Color(0.92, 0.75, 0.25), false, 0.3, true)
			n.add_child(f)
		"bow":
			# recurved limbs as an arc along the hand's vertical, string behind
			var st2 := SurfaceTool.new()
			st2.begin(Mesh.PRIMITIVE_TRIANGLES)
			var prev := Vector3.ZERO
			var segs := 14
			for i in segs + 1:
				var a := deg_to_rad(lerpf(-62.0, 62.0, float(i) / segs))
				var p := Vector3(0, sin(a) * 0.62, cos(a) * 0.62 - 0.6 + (0.05 if absf(a) > 0.9 else 0.0))
				if i > 0:
					var side := Vector3(0.015, 0, 0)
					var fwd := Vector3(0, 0, 0.012)
					for q in [prev - side, p - side, prev + side, prev + side, p - side, p + side, prev - fwd, p - fwd, prev + fwd, prev + fwd, p - fwd, p + fwd]:
						st2.add_vertex(q)
				prev = p
			st2.generate_normals()
			var limb := MeshInstance3D.new()
			limb.mesh = st2.commit()
			limb.material_override = Acc.mat(wood, false, 0.3, true)
			n.add_child(limb)
			var top := Vector3(0, sin(deg_to_rad(62.0)) * 0.62, cos(deg_to_rad(62.0)) * 0.62 - 0.55)
			n.add_child(Acc.box(Vector3(0.004, top.y * 2.0, 0.004), Color(0.92, 0.9, 0.82), Acc.at(Vector3(0, 0, top.z))))
		"boomerang":
			var bm := Acc.box(Vector3(0.05, 0.015, 0.3), wood, Acc.at(Vector3(0.08, 0, 0.1), Vector3(0, 30, 0)))
			n.add_child(bm)
			n.add_child(Acc.box(Vector3(0.05, 0.015, 0.3), wood, Acc.at(Vector3(-0.08, 0, 0.1), Vector3(0, -30, 0))))
	return n

static func shield_node(c: Color, trim: Color) -> Node3D:
	var n := Node3D.new()
	n.add_child(Acc.node(Acc.lathe([Vector2(0.0, 0.05), Vector2(0.18, 0.035), Vector2(0.3, 0.0), Vector2(0.31, -0.015), Vector2(0.0, -0.015)], 24), c))
	n.add_child(Acc.torus(0.27, 0.31, trim, Acc.at(Vector3(0, 0.0, 0))))
	n.add_child(Acc.sphere(0.06, trim, Acc.at(Vector3(0, 0.05, 0))))
	return n

# ---------------------------------------------------------------------------
# Building
# ---------------------------------------------------------------------------
## Returns the `parts` dictionary used by battle units.
static func build(unit, look: Dictionary) -> Dictionary:
	var actor = Actor.new()
	unit.add_child(actor)
	actor.setup(look)
	var p: Dictionary = actor.parts
	var sex: String = look.get("sex", "m")
	var hand_r := Vector3(-0.706, 1.455, -0.065) if sex == "m" else Vector3(-0.641, 1.418, -0.052)
	var hand_l := Vector3(-hand_r.x, hand_r.y, hand_r.z)
	var trim: Color = CB.PALETTES.get(look.get("culture", "earth"), CB.PALETTES.earth).accent
	var primary: Color = CB.PALETTES.get(look.get("culture", "earth"), CB.PALETTES.earth).primary
	var model: String = Data.item(unit.weapon_id).get("model", "none")
	if model != "none":
		var w := weapon(model, trim)
		w.transform = Transform3D(Basis(), hand_r + Vector3(-0.07, -0.03, 0.0))
		Acc.bind(p, "hand_r", w)
		if model in ["dual_dao", "hooks", "fans"]:
			var w2 := weapon(model, trim)
			w2.transform = Transform3D(Basis(), hand_l + Vector3(0.07, -0.03, 0.0))
			Acc.bind(p, "hand_l", w2)
	if unit.ranged_id != "":
		var rm: String = Data.item(unit.ranged_id).get("model", "bow")
		var rw := weapon(rm, trim)
		rw.visible = false
		rw.transform = Transform3D(Basis(), hand_l + Vector3(0.07, -0.02, 0.0))
		Acc.bind(p, "hand_l", rw)
		p.ranged = rw
	if unit.shield:
		var sh := shield_node(primary.darkened(0.2), trim)
		sh.transform = Transform3D(Basis(Vector3.BACK, -PI / 2.0), hand_l + Vector3(-0.12, -0.02, 0.0))
		Acc.bind(p, "lowerarm_l", sh)
	var seat := 0.0
	if unit.mount_id != "":
		var mp: Dictionary = Mount.build(Mount.kind_for_item(unit.mount_id))
		unit.add_child(mp.root)
		p.mount = mp.root
		p.mount_rig = mp
		seat = mp.seat
		actor.position.y = seat - RIDE_HIP
		actor.set_stance("ride")
	p.seat = seat
	p.actor = actor
	if unit.bend != "":
		var glow := OmniLight3D.new()
		glow.visible = false
		glow.light_color = Data.element_color(unit.bend)
		glow.omni_range = 3.0
		glow.light_energy = 2.0
		var gl_att := BoneAttachment3D.new()
		gl_att.bone_name = "hand_r"
		p.skeleton.add_child(gl_att)
		gl_att.add_child(glow)
		p.glow = glow
	if model in ["sword", "dao", "dual_dao", "jian", "machete", "space_sword", "hooks", "axe", "fans", "knife"]:
		actor.set_stance("sword" if unit.mount_id == "" else "ride")
	elif unit.bend != "" and unit.mount_id == "":
		actor.set_stance("bend")
	elif unit.shield and unit.mount_id == "":
		actor.set_stance("shield")
	return p

# ---------------------------------------------------------------------------
# Animation mapping
# ---------------------------------------------------------------------------
## Height of the hips above the floor in the sitting pose used for riding.
const RIDE_HIP := 0.48

const MELEE_ANIMS := {
	"blade": {"left": "ual2/Sword_Regular_B", "right": "ual2/Sword_Regular_A", "overhead": "ual2/Sword_Regular_C", "thrust": "ual1/Sword_Attack"},
	"pole": {"left": "ual2/Sword_Regular_B", "right": "ual2/Sword_Regular_A", "overhead": "ual2/Sword_Heavy_Combo", "thrust": "ual1/Sword_Attack"},
	"fist": {"left": "ual1/Punch_Jab", "right": "ual1/Punch_Cross", "overhead": "ual2/Melee_Hook", "thrust": "ual1/Punch_Cross"},
}

static func attack(unit, dir: String, total_time: float) -> void:
	var a = unit.parts.get("actor")
	if a == null:
		return
	var model: String = Data.item(unit.weapon_id).get("model", "none")
	var set := "fist"
	if model in ["spear", "guan_dao", "staff"]:
		set = "pole"
	elif model != "none" and model != "fists":
		set = "blade"
	var anim_name: String = MELEE_ANIMS[set].get(dir, MELEE_ANIMS[set].right)
	var length: float = a.action_length(anim_name)
	if anim_name == "ual2/Sword_Heavy_Combo":
		length *= 0.45
	a.action(anim_name, clampf(length / maxf(0.2, total_time), 0.6, 2.5))
	if unit.bend != "" and a.bend_pose:
		a.bend_pose.pulse("lunge")

const CAST_ANIMS := {
	"fire": {"q": ["ual1/Punch_Jab", "lunge"], "e": ["ual2/Melee_Hook", "sweep"], "r": ["ual1/Spell_Simple_Shoot", "lunge"]},
	"blue_fire": {"q": ["ual1/Punch_Cross", "lunge"], "e": ["ual2/Melee_Hook", "sweep"], "r": ["ual1/Spell_Simple_Shoot", "lunge"]},
	"earth": {"q": ["ual2/OverhandThrow", "stomp"], "e": ["ual1/Push", "push"], "r": ["ual1/Jump_Land", "stomp"]},
	"sand": {"q": ["ual2/OverhandThrow", "stomp"], "e": ["ual2/Melee_Hook", "sweep"], "r": ["ual1/Push", "push"]},
	"water": {"q": ["ual1/Spell_Simple_Shoot", "push"], "e": ["ual1/Interact", ""], "r": ["ual2/Sword_Regular_A", "sweep"]},
	"air": {"q": ["ual1/Spell_Simple_Shoot", "push"], "e": ["ual2/Sword_Regular_C", "sweep"], "r": ["ual2/NinjaJump_Land", "stomp"]},
}

static func cast(unit, slot: String) -> void:
	var a = unit.parts.get("actor")
	if a == null:
		return
	var entry: Array = CAST_ANIMS.get(unit.bend, CAST_ANIMS.fire).get(slot, ["ual1/Spell_Simple_Shoot", ""])
	var anim_name: String = entry[0]
	if unit.bend == "fire" and slot == "q" and randf() < 0.5:
		anim_name = "ual1/Punch_Cross"
	var full := anim_name in ["ual1/Jump_Land", "ual2/NinjaJump_Land"]
	a.action(anim_name, 1.5, full)
	if entry[1] != "" and a.bend_pose:
		a.bend_pose.pulse(entry[1])

## The Avatar State: a white blaze around the Avatar while it lasts.
static func avatar_glow(unit, on: bool) -> void:
	var p: Dictionary = unit.parts
	if on and not p.has("avatar_light"):
		var l := OmniLight3D.new()
		l.light_color = Color(0.85, 0.95, 1.0)
		l.omni_range = 6.0
		l.light_energy = 4.0
		l.position = Vector3(0, 1.4, 0)
		unit.add_child(l)
		p.avatar_light = l
	if p.has("avatar_light"):
		p.avatar_light.visible = on
	var a = p.get("actor")
	if a != null:
		a.set_expression("determined" if on else "neutral")

static func hit(unit, big: bool) -> void:
	var a = unit.parts.get("actor")
	if a == null:
		return
	a.action("ual2/Hit_Knockback" if big else ["ual1/Hit_Chest", "ual1/Hit_Head"].pick_random(), 1.3, not unit.mounted())
	a.set_expression("pain")

static func animate(unit, delta: float) -> void:
	var a = unit.parts.get("actor")
	if a == null:
		return
	var spd := Vector2(unit.vel.x, unit.vel.z).length()
	a.speed = 0.0 if unit.mounted() else spd
	# face
	if unit.hp < unit.max_hp * 0.3:
		a.set_expression("afraid")
	elif unit.action in ["windup", "cast"]:
		a.set_expression("furious" if unit.is_hero else "angry")
	elif unit.action == "stagger":
		a.set_expression("pain")
	else:
		a.set_expression("determined")
	# bending stance while fighting on foot
	if a.bend_pose:
		var engaged: bool = unit.target != null and is_instance_valid(unit.target) and unit.dist_to(unit.target) < 25.0
		var element: String = unit.bend if unit.bend != "blue_fire" else "fire"
		if element == "sand":
			element = "earth"
		a.bend_pose.set_form("ride" if unit.mounted() else (element if unit.bend != "" and engaged and spd < 2.0 else ""))
	if unit.parts.has("ranged"):
		unit.parts.ranged.visible = unit.action == "aim" or (unit.is_player and unit.battle.player_ranged_mode)
	if unit.parts.has("glow"):
		unit.parts.glow.visible = unit.cast_anim > 0.0
	# mount gallop
	if unit.parts.has("mount") and unit.mount_hp > 0.0 and unit.parts.has("mount_rig"):
		var gallop := clampf(spd / maxf(1.0, unit.mount_speed), 0.0, 1.0)
		unit.anim_t += delta
		Mount.animate(unit.parts.mount_rig, spd)
		# the rider rises and settles with the stride
		a.position.y = unit.parts.seat - RIDE_HIP + absf(sin(unit.anim_t * 9.0)) * 0.07 * gallop
