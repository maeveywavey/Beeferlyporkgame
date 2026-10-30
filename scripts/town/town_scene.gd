extends Node3D
## Walkable settlement: the player walks the streets in third person, with
## companions following, townspeople going about their day, and the
## settlement's services (market, smith, tavern, hall...) as people to talk
## to. Uses the same windows as the world map's settlement menu.

const TownLayout = preload("res://scripts/town/town_layout.gd")
const TownNpc = preload("res://scripts/town/town_npc.gd")
const Arch = preload("res://scripts/town/arch.gd")
const Actor = preload("res://scripts/actors/actor.gd")
const Looks = preload("res://scripts/actors/looks.gd")
const CB = preload("res://scripts/actors/character_builder.gd")
const Acc = preload("res://scripts/actors/accessories.gd")
const UnitVisual = preload("res://scripts/battle/unit_visual.gd")
const UI = preload("res://scripts/ui/ui.gd")
const Story = preload("res://scripts/story/story.gd")
const SettlementWindow = preload("res://scripts/ui/settlement_window.gd")
const DialogueWindow = preload("res://scripts/ui/dialogue_window.gd")

static var autotest := false

## Civilian dyes per culture, multiplied over the outfit texture.
const DYES := {
	"earth": [Color(1, 1, 1), Color(0.95, 0.85, 0.7), Color(0.8, 0.9, 0.75), Color(1.05, 0.95, 0.8), Color(0.85, 0.75, 0.65), Color(0.75, 0.85, 0.95)],
	"omashu": [Color(1, 1, 1), Color(0.9, 0.82, 1.0), Color(1.0, 0.92, 0.8), Color(0.85, 0.95, 0.8)],
	"fire": [Color(1, 1, 1), Color(1.05, 0.85, 0.8), Color(0.75, 0.7, 0.7), Color(1.0, 0.95, 0.8)],
	"water": [Color(1, 1, 1), Color(0.85, 0.9, 1.05), Color(1.0, 0.95, 0.9)],
	"south": [Color(1, 1, 1), Color(0.85, 0.9, 1.05), Color(0.95, 0.88, 0.8)],
	"hamakaze": [Color(1, 1, 1), Color(0.9, 1.0, 0.95), Color(1.0, 0.92, 0.85)],
	"air": [Color(1, 1, 1), Color(1.05, 0.95, 0.85)],
	"swamp": [Color(1, 1, 1), Color(0.85, 0.9, 0.75)],
}
const ROBES := {
	"earth": [Color(0.3, 0.46, 0.25), Color(0.62, 0.55, 0.36), Color(0.45, 0.32, 0.2), Color(0.75, 0.7, 0.55), Color(0.25, 0.38, 0.32)],
	"omashu": [Color(0.38, 0.48, 0.22), Color(0.45, 0.3, 0.52), Color(0.66, 0.58, 0.4)],
	"fire": [Color(0.6, 0.12, 0.08), Color(0.25, 0.12, 0.1), Color(0.75, 0.55, 0.25), Color(0.45, 0.08, 0.08)],
	"hamakaze": [Color(0.2, 0.25, 0.42), Color(0.62, 0.3, 0.18)],
	"swamp": [Color(0.4, 0.42, 0.25), Color(0.45, 0.35, 0.2)],
}
const HATS := {"earth": ["straw_hat", "straw_hat", "bandana"], "omashu": ["straw_hat", "bandana"], "fire": ["topknot", "fn_cap"], "hamakaze": ["straw_hat"],
	"water": ["parka"], "south": ["parka", "warpaint"]}

var sid := ""
var layout
var player: Node3D
var followers: Array = []
var npcs: Array = []
var cam: Camera3D
var cam_yaw := 0.0
var cam_pitch := -0.25
var cam_dist := 5.0
var modal_layer: Control
var prompt: Label
var hud: RichTextLabel
var _near := {}
var _captured := true
var _leaving := false

func _ready() -> void:
	sid = GS.flags.get("town_sid", "")
	if sid == "" or not Data.settlements.has(sid):
		sid = "ba_sing_se"
	if GS.player.is_empty():
		GS.new_game(GS.create_player("Lee", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1)))
	_environment()
	_ground()
	layout = TownLayout.build(self, sid)
	_spawn_player()
	_spawn_people()
	_night_lights()
	_build_ui()
	cam = Camera3D.new()
	cam.fov = 60.0
	cam.far = 500.0
	add_child(cam)
	_update_camera(1.0)
	if not autotest:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# ---------------------------------------------------------------------------
# World
# ---------------------------------------------------------------------------
func _daylight() -> float:
	var h := GS.hour_of_day()
	var dl := clampf(sin((h - 6.0) / 13.0 * PI), 0.0, 1.0)
	if GS.is_eclipse():
		dl = 0.12
	return dl

func _environment() -> void:
	var dl := _daylight()
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.08, 0.1, 0.22).lerp(Color(0.32, 0.54, 0.86), dl)
	sm.sky_horizon_color = Color(0.22, 0.2, 0.32).lerp(Color(0.8, 0.84, 0.9), dl)
	if GS.hour_of_day() > 17.0 and GS.hour_of_day() < 20.0:
		sm.sky_horizon_color = sm.sky_horizon_color.lerp(Color(1.0, 0.6, 0.4), 0.5)
	sm.ground_horizon_color = sm.sky_horizon_color
	sm.ground_bottom_color = Color(0.2, 0.18, 0.15)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.5, 0.72).lerp(Color(0.85, 0.83, 0.8), dl)
	env.ambient_light_energy = 0.4 + dl * 0.4
	env.fog_enabled = true
	env.fog_light_color = sm.sky_horizon_color
	env.fog_density = 0.0035
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-25.0 - dl * 40.0, 30.0 + GS.hour_of_day() * 5.0, 0)
	sun.light_energy = 0.22 + dl * 1.0
	sun.light_color = Color(0.62, 0.7, 1.0) if dl < 0.05 else Color(1, 0.95, 0.88)
	sun.shadow_enabled = false
	add_child(sun)

func _ground() -> void:
	var biome: String = GS.sim.biome_at(Data.settlements[sid].pos)
	var col := Color(0.44, 0.6, 0.32)
	match biome:
		"snow": col = Color(0.9, 0.94, 0.99)
		"desert": col = Color(0.84, 0.74, 0.52)
		"volcanic": col = Color(0.38, 0.34, 0.3)
		"swamp": col = Color(0.3, 0.38, 0.22)
		"highland", "mountain": col = Color(0.52, 0.58, 0.44)
	if Data.settlements[sid].culture in ["north", "south"]:
		col = Color(0.9, 0.94, 0.99)
	var b = Arch.Builder.new()
	b.box(Vector3(0, -0.1, 0), Vector3(420, 0.2, 420), col)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	var m: ShaderMaterial = Arch.material(false).duplicate()
	m.set_shader_parameter("brush_scale", 0.12)
	m.set_shader_parameter("brush_strength", 0.12)
	mi.material_override = m
	add_child(mi)
	# grass tufts and pebbles break up the ground near the paths
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sid) + 7
	var tufts := ["Grass_Common_Short", "Grass_Wispy_Short", "Clover_1", "Flower_3_Group", "Pebble_Round_2"]
	if col.r > 0.8 and col.b > 0.9:
		tufts = ["Pebble_Round_1", "Pebble_Round_3"]
	for i in 160:
		var p := Vector3(rng.randf_range(-60, 60), 0, rng.randf_range(-60, 60))
		if absf(p.x) < 15.0 and absf(p.z) < 15.0:
			continue
		var n: String = tufts[rng.randi() % tufts.size()]
		var ps: PackedScene = load("res://assets/nature/%s.gltf" % n)
		var node: Node3D = ps.instantiate()
		node.position = p
		node.rotation.y = rng.randf() * TAU
		node.scale = Vector3.ONE * rng.randf_range(0.8, 1.4)
		add_child(node)

func _night_lights() -> void:
	if _daylight() > 0.3:
		return
	var ls: Array = layout.lights.duplicate()
	ls.sort_custom(func(a, b): return a.length() < b.length())
	for i in mini(8, ls.size()):
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.72, 0.45)
		l.light_energy = 1.6
		l.omni_range = 9.0
		l.position = ls[i]
		add_child(l)

# ---------------------------------------------------------------------------
# People
# ---------------------------------------------------------------------------
func _spawn_player() -> void:
	player = Node3D.new()
	add_child(player)
	var a = Actor.new()
	a.name = "Actor"
	player.add_child(a)
	a.setup(Looks.player_look())
	player.position = layout.spawn
	player.rotation.y = PI
	var i := 0
	for cid in GS.player.companions:
		if i >= 3 or not Story.in_party(cid):
			continue
		var f := Node3D.new()
		add_child(f)
		var fa = Actor.new()
		fa.name = "Actor"
		f.add_child(fa)
		fa.setup(Looks.companion_look(cid))
		f.position = layout.spawn + Vector3((i - 1) * 1.4, 0, 2.0)
		f.rotation.y = PI
		f.set_meta("cid", cid)
		f.set_meta("slot", Vector3((i - 1) * 1.3, 0, 1.8 + (i % 2) * 0.6))
		followers.append(f)
		i += 1

func _role_look(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	var culture: String = Data.settlements[sid].culture
	var c: String = Looks.CULTURE_MAP.get(culture, "earth")
	match kind:
		"guard", "soldier":
			var tid: String = GS.culture_tree(culture)[mini(2, GS.culture_tree(culture).size() - 1)]
			if culture == "air":
				tid = "an_monk"
			return Looks.troop_look(tid, rng)
		"monk", "abbot":
			var l := CB.random_look("air", rng)
			l.merge({"outfit": "peasant", "kit": "air_robes", "accessory": "air_arrow" if kind == "abbot" else ""}, true)
			return l
	var look := CB.random_look(c, rng)
	var rich := kind in ["steward", "guildmaster", "promoter", "elder"]
	look.merge({"outfit": "ranger" if rich or rng.randf() < 0.35 else "peasant", "kit": ["sash", "", ""][rng.randi() % 3] if c != "air" else "air_robes", "accessory": ""}, true)
	# Dyes vary from person to person; hats and hairstyles by culture
	var dyes: Array = DYES.get(c, DYES.earth)
	look.cloth_tint = dyes[rng.randi() % dyes.size()] * rng.randf_range(0.9, 1.08)
	# the poor wear faded, patched peasant clothes; beggars more so
	var w: int = layout.wealth if layout != null else 1
	if kind == "beggar" or (w == 0 and not rich):
		look.outfit = "peasant"
		look.kit = ""
		look.cloth_tint = look.cloth_tint.lerp(Color(0.45, 0.4, 0.33), 0.6 if kind == "beggar" else 0.35)
		if kind == "beggar":
			return look
	elif w == 2 and rng.randf() < 0.5:
		look.outfit = "ranger"
	# many civilians, women especially, wear the long wrap robe of their people
	if c != "air" and c != "water" and c != "south" and rng.randf() < (0.65 if look.sex == "f" else 0.25):
		look.kit = "civ_robe"
		var robes: Array = ROBES.get(c, ROBES.earth)
		look.robe_color = robes[rng.randi() % robes.size()]
	var hats: Array = HATS.get(c, [])
	if not hats.is_empty() and rng.randf() < 0.4:
		look.accessory = hats[rng.randi() % hats.size()]
	if kind in ["elder", "abbot"] or rng.randf() < 0.15:
		look.hair_color = Color(0.62, 0.6, 0.58)
	if kind == "smith":
		look.kit = ""
	if c == "water" or c == "south":
		look.kit = "water_fur"
		look.accessory = "parka" if rng.randf() < 0.5 else ""
	return look

func _spawn_people() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sid) + 11
	for sp in layout.spots:
		var role: Dictionary = sp.role
		var n = TownNpc.new()
		n.position = sp.pos
		n.rotation.y = sp.rot
		add_child(n)
		var lk: String = role.get("look", "")
		n.setup(_role_look(lk, rng), sp.stance, sp.loop, "idle", [])
		n.player = player
		if role.has("action"):
			n.talk_radius = 5.0
			n.set_meta("label", role.label)
		if lk in ["guard", "soldier"]:
			_arm(n, "spear" if lk == "guard" else "sword")
		npcs.append(n)
	var count: int = {"town": 16, "castle": 6, "village": 7, "temple": 6}.get(Data.settlements[sid].type, 8)
	if layout.waypoints.is_empty():
		return
	for i in count:
		var n2 = TownNpc.new()
		n2.position = layout.waypoints[rng.randi() % layout.waypoints.size()]
		add_child(n2)
		var lk2 := "soldier" if Data.settlements[sid].type == "castle" else ("monk" if Data.settlements[sid].type == "temple" else "")
		n2.setup(_role_look(lk2, rng), "", "", "wander", layout.waypoints)
		n2.walk_speed = rng.randf_range(1.0, 1.45)
		npcs.append(n2)

func _arm(n: Node3D, model: String) -> void:
	var a = n.actor
	var sex: String = a.look.get("sex", "m")
	var hand_r := Vector3(-0.706, 1.455, -0.065) if sex == "m" else Vector3(-0.641, 1.418, -0.052)
	var w := UnitVisual.weapon(model, Color(0.8, 0.65, 0.3))
	w.transform = Transform3D(Basis(), hand_r + Vector3(-0.07, -0.03, 0.0))
	Acc.bind(a.parts, "hand_r", w)

# ---------------------------------------------------------------------------
# Frame update: movement, followers, camera, prompts
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if _leaving:
		return
	var modal := is_modal_open()
	if modal and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif not modal and _captured and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not autotest:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var a = player.get_node("Actor")
	if not modal:
		var mv := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_forward", "move_back"))
		if mv.length() > 1.0:
			mv = mv.normalized()
		var speed := 1.5 if Input.is_action_pressed("walk") else 3.8
		var basis := Basis(Vector3.UP, cam_yaw)
		var dir := basis * Vector3(mv.x, 0, mv.y)
		if dir.length() > 0.01:
			_move(player, dir * speed * delta)
			player.rotation.y = lerp_angle(player.rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 10.0))
			a.speed = speed * mv.length()
		else:
			a.speed = 0.0
		# leaving through the gate
		if player.position.z > layout.bounds + 0.5 and absf(player.position.x) < 6.0:
			leave()
			return
	else:
		a.speed = 0.0
	_follow(delta)
	_update_camera(delta)
	_update_prompt()
	_check_story()

func _move(n: Node3D, step: Vector3) -> void:
	var p := n.position + step
	var q := Vector2(p.x, p.z)
	for o in layout.obstacles:
		if o.has("r"):
			var d = q - o.c
			var rr: float = o.r + 0.35
			if d.length() < rr:
				q = o.c + d.normalized() * rr
		else:
			var hx: float = o.h.x + 0.35
			var hz: float = o.h.y + 0.35
			var dx = q.x - o.c.x
			var dz = q.y - o.c.y
			if absf(dx) < hx and absf(dz) < hz:
				# push out along the shallower axis
				if hx - absf(dx) < hz - absf(dz):
					q.x = o.c.x + signf(dx) * hx
				else:
					q.y = o.c.y + signf(dz) * hz
	var lim: float = layout.bounds
	var gate_open := absf(q.x) < 6.0
	q.x = clampf(q.x, -lim, lim)
	q.y = clampf(q.y, -lim, lim + (4.0 if gate_open else 0.0))
	n.position = Vector3(q.x, 0, q.y)

func _follow(delta: float) -> void:
	var basis := Basis(Vector3.UP, player.rotation.y)
	for f in followers:
		var want: Vector3 = player.position + basis * (-f.get_meta("slot"))
		var to: Vector3 = want - f.position
		to.y = 0.0
		var fa = f.get_node("Actor")
		if to.length() > 0.6:
			var spd := clampf(to.length() * 1.6, 1.2, 4.6)
			_move(f, to.normalized() * spd * delta)
			f.rotation.y = lerp_angle(f.rotation.y, atan2(to.x, to.z), minf(1.0, delta * 8.0))
			fa.speed = spd
		else:
			fa.speed = 0.0

func _input(event: InputEvent) -> void:
	if _leaving:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = float(GS.settings.get("mouse_sens", 0.25)) * 0.01
		cam_yaw -= event.relative.x * sens
		cam_pitch = clampf(cam_pitch - event.relative.y * sens * (-1.0 if GS.settings.get("invert_y", false) else 1.0), -1.1, 0.35)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist = maxf(2.5, cam_dist - 0.4)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist = minf(10.0, cam_dist + 0.4)
		elif not is_modal_open():
			_captured = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if is_modal_open():
			return
		match event.physical_keycode:
			KEY_E, KEY_F:
				_interact()
			KEY_TAB:
				leave()
			KEY_ESCAPE:
				_captured = not _captured
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _captured else Input.MOUSE_MODE_VISIBLE

func _update_camera(delta: float) -> void:
	var target := player.position + Vector3(0, 1.6, 0)
	var dir := Basis(Vector3.UP, cam_yaw) * Basis(Vector3.RIGHT, cam_pitch) * Vector3(0, 0, -1)
	var want := target - dir * cam_dist
	want.y = maxf(0.4, want.y)
	cam.position = cam.position.lerp(want, minf(1.0, delta * 12.0)) if delta < 0.9 else want
	cam.look_at(target, Vector3.UP)

func _update_prompt() -> void:
	_near = {}
	var best := 2.8
	for it in layout.interacts:
		var d := player.position.distance_to(it.pos)
		if d < best:
			best = d
			_near = it
	prompt.text = "" if _near.is_empty() else "[E]  " + _near.label
	prompt.visible = not _near.is_empty() and not is_modal_open()

func _interact() -> void:
	if _near.is_empty():
		return
	GS.player.inside = sid
	var action: String = _near.action
	match action:
		"trade":
			_open_sub("res://scripts/ui/trade_window.gd")
		"shop":
			_open_sub("res://scripts/ui/shop_window.gd")
		"tavern", "hall", "arena", "council", "recruit":
			_open_settlement(action)
		"work":
			var w = _open_settlement("main")
			w.call_deferred("_ask_work")
		_:
			_open_settlement("main")

func _open_sub(path: String) -> void:
	var w = load(path).new()
	w.sid = sid
	open_window(w)

func _open_settlement(page: String) -> Control:
	var w = SettlementWindow.new()
	w.sid = sid
	w.page = page
	open_window(w)
	return w

# ---------------------------------------------------------------------------
# Window API shared with the world map (settlement, trade, dialogue windows)
# ---------------------------------------------------------------------------
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var rootc := Control.new()
	rootc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rootc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rootc.theme = UI.theme()
	layer.add_child(rootc)
	hud = RichTextLabel.new()
	hud.bbcode_enabled = true
	hud.fit_content = true
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.position = Vector2(16, 12)
	hud.size = Vector2(900, 80)
	hud.add_theme_color_override("default_color", Color(1, 0.96, 0.88))
	hud.add_theme_constant_override("outline_size", 6)
	hud.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.04))
	var d: Dictionary = Data.settlements[sid]
	hud.text = UI.scale_bbcode("[font_size=26][b]%s[/b][/font_size]\n%s  ·  %s\n[font_size=14]WASD move · Shift walk · Mouse look · E talk · Tab or the gate: back to the map · Esc: free the mouse[/font_size]" % [
		d.name, Data.factions.get(GS.settlements[sid].faction, Data.factions.neutral).name, GS.date_string()])
	rootc.add_child(hud)
	prompt = Label.new()
	prompt.add_theme_font_size_override("font_size", UI.px(22))
	prompt.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	prompt.add_theme_constant_override("outline_size", 6)
	prompt.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.04))
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position.y -= 120
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rootc.add_child(prompt)
	modal_layer = Control.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rootc.add_child(modal_layer)

func is_modal_open() -> bool:
	return modal_layer != null and modal_layer.get_child_count() > 0

func open_window(w: Control) -> void:
	if "map" in w:
		w.map = self
	modal_layer.add_child(w)

func close_all_windows() -> void:
	for c in modal_layer.get_children():
		c.queue_free()

func open_dialogue(id: String) -> Control:
	if id == "" or not Story.has_dialogue(id):
		return null
	var w = DialogueWindow.new()
	w.dlg_id = id
	open_window(w)
	return w

func _check_story() -> void:
	if not is_modal_open() and Story.has_pending():
		open_dialogue(Story.pop_pending())

## Resting from a town menu returns to the map and waits there.
func start_waiting(hours: float) -> void:
	GS.flags.town_wait = hours
	leave()

func leave() -> void:
	if _leaving:
		return
	_leaving = true
	GS.flags.town_return = sid
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file.call_deferred("res://scenes/world_map.tscn")
