extends Node3D
## The strategic world map: renders the world, lets the player travel,
## advances time and opens the menus for encounters and settlements.

const UI = preload("res://scripts/ui/ui.gd")
const MapBuilder = preload("res://scripts/world/map_builder.gd")
const Terrain = preload("res://scripts/core/terrain.gd")
const Roster = preload("res://scripts/core/roster.gd")
const Economy = preload("res://scripts/core/economy.gd")
const Quests = preload("res://scripts/core/quests.gd")

const EncounterWindow = preload("res://scripts/ui/encounter_window.gd")
const SettlementWindow = preload("res://scripts/ui/settlement_window.gd")
const PartyWindow = preload("res://scripts/ui/party_window.gd")
const CharacterWindow = preload("res://scripts/ui/character_window.gd")
const InventoryWindow = preload("res://scripts/ui/inventory_window.gd")
const QuestWindow = preload("res://scripts/ui/quest_window.gd")
const FactionWindow = preload("res://scripts/ui/faction_window.gd")
const CampWindow = preload("res://scripts/ui/camp_window.gd")
const ResultWindow = preload("res://scripts/ui/result_window.gd")

const SIGHT := 70.0

var camera: Camera3D
var cam_target := Vector3.ZERO
var cam_dist := 90.0
var cam_yaw := 0.0
var follow_player := true
var sun: DirectionalLight3D
var env: Environment

var settlement_nodes := {}
var settlement_banners := {}
var party_nodes := {}

var hud: CanvasLayer
var labels_layer: Control
var modal_layer: Control
var top_label: RichTextLabel
var log_box: VBoxContainer
var tooltip: PanelContainer
var tooltip_label: Label
var status_label: Label
var settlement_labels := {}
var party_labels := {}

var waiting := false
var wait_until := -1.0
var paused := false
var fast := false
var _dragging := false
var _drag_last := Vector2.ZERO
var _hud_timer := 0.0

func _ready() -> void:
	if not GS.game_active:
		get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
		return
	_build_environment()
	MapBuilder.build_terrain(self)
	_build_settlements()
	_build_hud()
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.far = 3000.0
	add_child(camera)
	var pp: Dictionary = GS.player_party()
	cam_target = Vector3(pp.pos.x, 0, pp.pos.y)
	_update_camera(1.0)
	GS.message.connect(_on_message)
	GS.player_encounter.connect(_on_player_encounter)
	GS.player_arrived.connect(_on_player_arrived)
	for l in GS.log_lines.slice(-6):
		_add_log_line(l.t, l.c)
	if not GS.last_battle_result.is_empty():
		var rw = ResultWindow.new()
		rw.result = GS.last_battle_result
		GS.last_battle_result = {}
		open_window(rw)
	GS.sim.reset_clock()

# ---------------------------------------------------------------------------
# Scene construction
# ---------------------------------------------------------------------------
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.62, 0.8)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.8)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.6, 0.7, 0.8)
	env.fog_density = 0.0012
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = false
	add_child(sun)

func _build_settlements() -> void:
	for sid in Data.settlements:
		var d: Dictionary = Data.settlements[sid]
		var node := MapBuilder.build_settlement(sid)
		node.position = Vector3(d.pos.x, Terrain.surface(d.pos), d.pos.y)
		add_child(node)
		settlement_nodes[sid] = node
		if d.type != "ruin":
			var banner := MapBuilder.build_banner(8.0 if d.type == "town" else 6.5)
			banner.position = node.position + Vector3(-3.0, 0, -3.0)
			add_child(banner)
			settlement_banners[sid] = banner
	_refresh_banners()

func _refresh_banners() -> void:
	for sid in settlement_banners:
		var f: String = GS.settlements[sid].faction
		MapBuilder.set_banner_color(settlement_banners[sid], Data.factions.get(f, Data.factions.neutral).color)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.theme()
	hud.add_child(root)
	labels_layer = Control.new()
	labels_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	labels_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(labels_layer)
	# Top bar
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(top)
	var row := UI.hbox(8)
	top.add_child(row)
	top_label = UI.rich("", 700)
	top_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(top_label)
	for b in [["Camp (T)", _open_camp], ["Party (P)", _open_party], ["Character (C)", _open_character],
			["Inventory (I)", _open_inventory], ["Quests (J)", _open_quests], ["Factions (N)", _open_factions]]:
		row.add_child(UI.button(b[0], b[1]))
	# Bottom-left message log
	log_box = UI.vbox(2)
	log_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	log_box.position = Vector2(12, -230)
	log_box.custom_minimum_size = Vector2(620, 220)
	log_box.alignment = BoxContainer.ALIGNMENT_END
	log_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(log_box)
	log_box.anchor_top = 1.0
	log_box.anchor_bottom = 1.0
	log_box.offset_top = -240
	log_box.offset_bottom = -10
	# Bottom-right status / time controls
	var tc := PanelContainer.new()
	tc.anchor_left = 1.0
	tc.anchor_right = 1.0
	tc.anchor_top = 1.0
	tc.anchor_bottom = 1.0
	tc.offset_left = -420
	tc.offset_top = -64
	tc.offset_right = -10
	tc.offset_bottom = -10
	root.add_child(tc)
	var trow := UI.hbox(6)
	tc.add_child(trow)
	status_label = UI.label("", 16)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trow.add_child(status_label)
	trow.add_child(UI.button("Wait", func(): start_waiting(-1.0)))
	trow.add_child(UI.button("||", func():
		waiting = false
		GS.player_party().moving = false
		GS.player_party().target_party = ""))
	trow.add_child(UI.button(">>", func(): fast = not fast))
	# Tooltip
	tooltip = PanelContainer.new()
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.visible = false
	root.add_child(tooltip)
	tooltip_label = UI.label("", 15)
	tooltip.add_child(tooltip_label)
	# Modal layer above everything
	modal_layer = Control.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(modal_layer)
	# Labels for settlements
	for sid in Data.settlements:
		var l := _make_world_label(Data.settlements[sid].name, 15 if Data.settlements[sid].type != "village" else 13)
		settlement_labels[sid] = l

func _make_world_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.02))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels_layer.add_child(l)
	return l

# ---------------------------------------------------------------------------
# Windows
# ---------------------------------------------------------------------------
func is_modal_open() -> bool:
	return modal_layer != null and modal_layer.get_child_count() > 0

func open_window(w: Control) -> void:
	if "map" in w:
		w.map = self
	modal_layer.add_child(w)
	w.tree_exited.connect(_on_window_closed)

func close_all_windows() -> void:
	for c in modal_layer.get_children():
		c.queue_free()

func _on_window_closed() -> void:
	_refresh_banners()

func _open_camp() -> void:
	if not is_modal_open():
		open_window(CampWindow.new())

func _open_party() -> void:
	if not is_modal_open():
		open_window(PartyWindow.new())

func _open_character() -> void:
	if not is_modal_open():
		open_window(CharacterWindow.new())

func _open_inventory() -> void:
	if not is_modal_open():
		open_window(InventoryWindow.new())

func _open_quests() -> void:
	if not is_modal_open():
		open_window(QuestWindow.new())

func _open_factions() -> void:
	if not is_modal_open():
		open_window(FactionWindow.new())

func open_settlement(sid: String) -> void:
	var w = SettlementWindow.new()
	w.sid = sid
	open_window(w)

func _on_player_encounter(pid: String) -> void:
	waiting = false
	var w = EncounterWindow.new()
	w.pid = pid
	open_window(w)

func _on_player_arrived(sid: String) -> void:
	waiting = false
	Quests.on_arrive(sid)
	open_settlement(sid)

func start_waiting(hours: float) -> void:
	waiting = true
	wait_until = GS.hours + hours if hours > 0.0 else -1.0
	GS.player_party().moving = false

# ---------------------------------------------------------------------------
# Frame update
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if not GS.game_active:
		return
	var pp: Dictionary = GS.player_party()
	var captive: bool = GS.player.get("captive_until", -1.0) > GS.hours
	if not is_modal_open():
		var running: bool = pp.moving or waiting or captive
		if running:
			var speed := 1.0
			if fast or Input.is_action_pressed("map_fast"):
				speed = 4.0
			if captive:
				speed = 8.0
			GS.sim.advance(delta * speed)
			if waiting and wait_until > 0.0 and GS.hours >= wait_until:
				waiting = false
				var inside: String = GS.player.get("inside", "")
				var siege_sid: String = GS.player.get("siege_return", "")
				GS.player.siege_return = ""
				if inside != "":
					GS.player.inside = ""
					open_settlement(inside)
				elif siege_sid != "" and GS.settlements[siege_sid].siege.get("leader", "") == "player":
					open_settlement(siege_sid)
		_handle_camera_keys(delta)
	if follow_player:
		var target := Vector3(pp.pos.x, Terrain.surface(pp.pos), pp.pos.y)
		cam_target = cam_target.lerp(target, minf(1.0, delta * 4.0))
	_update_camera(delta)
	_update_parties(delta)
	_update_lighting()
	_update_labels()
	_hud_timer -= delta
	if _hud_timer <= 0.0:
		_hud_timer = 0.2
		_update_hud(captive)
	_update_tooltip()

func _handle_camera_keys(delta: float) -> void:
	var move := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		move.z -= 1
	if Input.is_action_pressed("move_back"):
		move.z += 1
	if Input.is_action_pressed("move_left"):
		move.x -= 1
	if Input.is_action_pressed("move_right"):
		move.x += 1
	if move != Vector3.ZERO:
		follow_player = false
		cam_target += move.normalized().rotated(Vector3.UP, cam_yaw) * cam_dist * 0.9 * delta
		cam_target.x = clampf(cam_target.x, 0, Data.MAP_W)
		cam_target.z = clampf(cam_target.z, 0, Data.MAP_H)

func _update_camera(_delta: float) -> void:
	var pitch := deg_to_rad(lerpf(45.0, 62.0, clampf((cam_dist - 30.0) / 300.0, 0.0, 1.0)))
	var offset := Vector3(0, sin(pitch), cos(pitch)).rotated(Vector3.UP, cam_yaw) * cam_dist
	camera.position = cam_target + offset
	camera.look_at(cam_target, Vector3.UP)

func _update_lighting() -> void:
	var h := GS.hour_of_day()
	var daylight := clampf(sin((h - 6.0) / 13.0 * PI), 0.0, 1.0)
	if GS.is_eclipse():
		daylight = 0.15
	sun.light_energy = 0.25 + daylight * 0.95
	sun.light_color = Color(1.0, 0.85, 0.7).lerp(Color(1, 1, 0.97), daylight)
	if daylight <= 0.01:
		sun.light_color = Color(0.6, 0.7, 1.0)
	env.ambient_light_energy = 0.35 + daylight * 0.35
	env.ambient_light_color = Color(0.45, 0.5, 0.75).lerp(Color(0.78, 0.78, 0.8), daylight)
	var sky := Color(0.08, 0.1, 0.2).lerp(Color(0.45, 0.62, 0.8), daylight)
	if GS.is_comet():
		sky = sky.lerp(Color(0.8, 0.25, 0.1), 0.45)
		sun.light_color = sun.light_color.lerp(Color(1, 0.4, 0.2), 0.4)
	env.background_color = sky
	env.fog_light_color = sky.lightened(0.15)
	sun.rotation_degrees.x = -25.0 - daylight * 40.0

func _player_sight() -> float:
	return SIGHT + GS.skill("pathfinding") * 4.0

func _update_parties(delta: float) -> void:
	var pp: Dictionary = GS.player_party()
	var sight := _player_sight()
	# Remove nodes for parties that no longer exist
	for id in party_nodes.keys():
		if not GS.parties.has(id):
			party_nodes[id].queue_free()
			party_nodes.erase(id)
			if party_labels.has(id):
				party_labels[id].queue_free()
				party_labels.erase(id)
	for id in GS.parties:
		var p: Dictionary = GS.parties[id]
		if not party_nodes.has(id):
			var n := MapBuilder.build_party(p)
			add_child(n)
			party_nodes[id] = n
			n.position = Vector3(p.pos.x, Terrain.surface(p.pos), p.pos.y)
		var node: Node3D = party_nodes[id]
		var visible_now: bool = id == "player" or p.pos.distance_to(pp.pos) <= sight or p.get("besieging", "") != ""
		if id == "player" and GS.player.get("captive_until", -1.0) > GS.hours:
			visible_now = false
		node.visible = visible_now
		var target := Vector3(p.pos.x, Terrain.surface(p.pos), p.pos.y)
		var old := node.position
		node.position = old.lerp(target, minf(1.0, delta * 10.0))
		var mv := Vector2(target.x - old.x, target.z - old.z)
		if mv.length() > 0.01:
			node.rotation.y = lerp_angle(node.rotation.y, atan2(mv.x, mv.y), minf(1.0, delta * 8.0))
		var body := node.get_node_or_null("Body")
		if body and p.kind == "avatar":
			body.position.y = 7.0 + sin(Time.get_ticks_msec() / 600.0) * 0.6
		elif body and p.moving and visible_now:
			body.position.y = absf(sin(Time.get_ticks_msec() / 120.0)) * 0.25

func _update_labels() -> void:
	var vp := get_viewport().get_visible_rect().size
	var show_villages := cam_dist < 260.0
	for sid in settlement_labels:
		var l: Label = settlement_labels[sid]
		var d: Dictionary = Data.settlements[sid]
		var wp: Vector3 = settlement_nodes[sid].position + Vector3(0, 9.0 if d.type == "town" else 6.0, 0)
		if camera.is_position_behind(wp) or (d.type == "village" and not show_villages):
			l.visible = false
			continue
		var sp := camera.unproject_position(wp)
		l.visible = sp.x > -100 and sp.x < vp.x + 100 and sp.y > -50 and sp.y < vp.y + 50
		var s: Dictionary = GS.settlements[sid]
		var txt: String = d.name
		if not s.siege.is_empty():
			txt += " (besieged)"
		elif s.looted_until > GS.hours:
			txt += " (looted)"
		if l.text != txt:
			l.text = txt
		var fc: Color = Data.factions.get(s.faction, Data.factions.neutral).color
		l.add_theme_color_override("font_color", Color(1, 0.97, 0.88).lerp(fc.lightened(0.4), 0.45))
		l.position = sp - Vector2(l.size.x / 2.0, l.size.y)
	# Party labels for visible lords, the player and nearby parties
	for id in party_nodes:
		var node: Node3D = party_nodes[id]
		var p: Dictionary = GS.parties[id]
		var want: bool = node.visible and (p.kind in ["lord", "player", "avatar"] or cam_dist < 140.0)
		if want and not party_labels.has(id):
			party_labels[id] = _make_world_label("", 13)
		if not party_labels.has(id):
			continue
		var l: Label = party_labels[id]
		if not want:
			l.visible = false
			continue
		var wp := node.position + Vector3(0, 9.0 if p.kind == "avatar" else 4.2, 0)
		if camera.is_position_behind(wp):
			l.visible = false
			continue
		l.visible = true
		var size = GS.sim.party_size(p)
		var txt: String = "%s (%d)" % [p.name, size]
		if l.text != txt:
			l.text = txt
		var col := Color(1, 1, 1)
		if id != "player" and GS.parties_hostile(GS.player_party(), p):
			col = Color(1, 0.55, 0.45)
		elif p.kind == "avatar":
			col = Color(1, 0.8, 0.4)
		l.add_theme_color_override("font_color", col)
		l.position = camera.unproject_position(wp) - Vector2(l.size.x / 2.0, l.size.y)

func _update_hud(captive: bool) -> void:
	var pl: Dictionary = GS.player
	var pp: Dictionary = GS.player_party()
	var food_days := GS.food_days()
	var food_col := "2b1d10" if food_days > 3 else "b03020"
	var t := "[b]%s[/b]  ·  %s" % [GS.date_string(), GS.moon_string()]
	if GS.is_comet():
		t += "  ·  [color=#ff5522]SOZIN'S COMET[/color]"
	if GS.is_eclipse():
		t += "  ·  [color=#aa88ff]SOLAR ECLIPSE[/color]"
	t += "\nGold [color=#9a6a00]%d[/color]   Party %d/%d   Wounded %d   Prisoners %d   Food [color=#%s]%.1f days[/color]   Morale %d   Renown %d   HP %d/%d" % [
		pl.gold, GS.party_size(), GS.party_limit(), Roster.wounded(pp.roster), Roster.total(pp.prisoners),
		food_col, food_days, int(pl.morale), pl.renown, pl.hp, GS.max_hp()]
	top_label.text = t
	var st := ""
	if captive:
		st = "You are a captive... (%d h)" % int(pl.captive_until - GS.hours)
	elif waiting:
		st = "Waiting..."
	elif pp.moving:
		st = "Travelling" + (" (x4)" if fast or Input.is_action_pressed("map_fast") else "")
	else:
		st = "Paused — click to travel"
	status_label.text = st

func _update_tooltip() -> void:
	if is_modal_open() or _dragging:
		tooltip.visible = false
		return
	var mp := get_viewport().get_mouse_position()
	var pick := _pick(mp)
	if pick.is_empty():
		tooltip.visible = false
		return
	var txt := ""
	if pick.type == "settlement":
		var sid: String = pick.id
		var d: Dictionary = Data.settlements[sid]
		var s: Dictionary = GS.settlements[sid]
		txt = "%s (%s)\n%s" % [d.name, d.type.capitalize(), Data.factions[s.faction].name]
		if s.owner != "" and Data.lords.has(s.owner):
			txt += "\nLord: " + Data.lords[s.owner].name
		elif s.owner == "player":
			txt += "\nLord: You"
		if d.type in ["town", "castle"]:
			txt += "\nGarrison: %d" % Roster.total(s.garrison)
		if d.type != "ruin":
			txt += "\nProsperity: %d" % int(s.prosperity)
	else:
		var p: Dictionary = GS.parties[pick.id]
		txt = "%s\n%s\nTroops: %d" % [p.name, Data.factions.get(GS.party_faction(p), Data.factions.neutral).name, GS.sim.party_size(p)]
		if p.id != "player":
			var ratio: float = GS.sim.party_power(p) / maxf(1.0, GS.sim.party_power(GS.player_party()))
			var strength := "much weaker" if ratio < 0.5 else ("weaker" if ratio < 0.9 else ("evenly matched" if ratio < 1.15 else ("stronger" if ratio < 2.0 else "much stronger")))
			txt += "\nStrength: " + strength
			if GS.parties_hostile(GS.player_party(), p):
				txt += "\n(Hostile)"
	tooltip_label.text = txt
	tooltip.visible = true
	tooltip.reset_size()
	tooltip.position = mp + Vector2(18, 18)

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if is_modal_open():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			cam_dist = maxf(25.0, cam_dist * 0.88)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			cam_dist = minf(700.0, cam_dist * 1.14)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = mb.pressed
			_drag_last = mb.position
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_on_left_click(mb.position, mb.double_click)
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			cam_yaw -= mm.relative.x * 0.005
		else:
			follow_player = false
			var d := Vector3(-mm.relative.x, 0, -mm.relative.y).rotated(Vector3.UP, cam_yaw) * cam_dist * 0.0018
			cam_target += d
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		match k.physical_keycode:
			KEY_SPACE:
				waiting = false
				GS.player_party().moving = false
				GS.player_party().target_party = ""
			KEY_F, KEY_HOME:
				follow_player = true
			KEY_T: _open_camp()
			KEY_P: _open_party()
			KEY_C: _open_character()
			KEY_I: _open_inventory()
			KEY_J: _open_quests()
			KEY_N: _open_factions()
			KEY_ESCAPE: _open_camp()

func _on_left_click(pos: Vector2, _double: bool) -> void:
	if GS.player.get("captive_until", -1.0) > GS.hours:
		return
	waiting = false
	GS.player.inside = ""
	var pp: Dictionary = GS.player_party()
	var pick := _pick(pos)
	if not pick.is_empty():
		if pick.type == "settlement":
			pp.target_settlement = pick.id
			pp.target_party = ""
			pp.moving = true
			if Data.settlements[pick.id].pos.distance_to(pp.pos) < 3.0:
				pp.moving = false
				pp.target_settlement = ""
				_on_player_arrived(pick.id)
			return
		elif pick.id != "player":
			pp.target_party = pick.id
			pp.target_settlement = ""
			pp.moving = true
			return
	var ground := _ground_point(pos)
	if ground != Vector2.INF:
		pp.target = ground
		pp.target_party = ""
		pp.target_settlement = ""
		pp.moving = true
		follow_player = true

func _ground_point(screen: Vector2) -> Vector2:
	var from := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	if absf(dir.y) < 0.001:
		return Vector2.INF
	var plane_y := 0.0
	var hit := Vector3.ZERO
	for i in 3:
		var t := (plane_y - from.y) / dir.y
		if t < 0:
			return Vector2.INF
		hit = from + dir * t
		plane_y = Terrain.surface(Vector2(hit.x, hit.z))
	return Vector2(clampf(hit.x, 2, Data.MAP_W - 2), clampf(hit.z, 2, Data.MAP_H - 2))

func _pick(screen: Vector2) -> Dictionary:
	var best := {}
	var bd := 26.0
	for id in party_nodes:
		var n: Node3D = party_nodes[id]
		if not n.visible or id == "player":
			continue
		var wp := n.position + Vector3(0, 8.0 if GS.parties[id].kind == "avatar" else 1.5, 0)
		if camera.is_position_behind(wp):
			continue
		var d := camera.unproject_position(wp).distance_to(screen)
		if d < bd:
			bd = d
			best = {"type": "party", "id": id}
	if best.is_empty():
		bd = 34.0
		for sid in settlement_nodes:
			var wp2: Vector3 = settlement_nodes[sid].position + Vector3(0, 2, 0)
			if camera.is_position_behind(wp2):
				continue
			var d2 := camera.unproject_position(wp2).distance_to(screen)
			if d2 < bd:
				bd = d2
				best = {"type": "settlement", "id": sid}
	return best

# ---------------------------------------------------------------------------
# Messages
# ---------------------------------------------------------------------------
func _on_message(text: String, color: Color) -> void:
	_add_log_line(text, color)

func _add_log_line(text: String, color: Color) -> void:
	if log_box == null:
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 600
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_box.add_child(l)
	while log_box.get_child_count() > 8:
		var c := log_box.get_child(0)
		log_box.remove_child(c)
		c.queue_free()
	var tw := l.create_tween()
	tw.tween_interval(14.0)
	tw.tween_property(l, "modulate:a", 0.35, 2.0)
