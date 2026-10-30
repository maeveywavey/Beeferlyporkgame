extends Node3D
## The strategic world map: renders the world, lets the player travel,
## advances time and opens the menus for encounters and settlements.

const UI = preload("res://scripts/ui/ui.gd")
const UISkin = preload("res://scripts/ui/skin.gd")
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
const DialogueWindow = preload("res://scripts/ui/dialogue_window.gd")
const EpilogueWindow = preload("res://scripts/ui/epilogue_window.gd")
const Story = preload("res://scripts/story/story.gd")

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
var date_label: Label
var season_seal: Control
var hud_chips := {}
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
	Music.play("map")
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
	if not GS.flags.has("seen_help"):
		GS.flags.seen_help = true
		open_window(load("res://scripts/ui/help_window.gd").new())
	# back from walking a settlement: reopen its menu, or keep resting there
	var back: String = GS.flags.get("town_return", "")
	if back != "":
		GS.flags.town_return = ""
		var wait: float = float(GS.flags.get("town_wait", 0.0))
		GS.flags.town_wait = 0.0
		if wait != 0.0:
			GS.player.inside = back
			start_waiting(wait)
		else:
			open_settlement(back)
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
	MapBuilder.update_borders()
	for sid in settlement_banners:
		var f: String = GS.settlements[sid].faction
		MapBuilder.set_banner_color(settlement_banners[sid], Data.factions.get(f, Data.factions.neutral).color)

var _top_bar: Control

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
	# Top bar: a lacquer banner with the season's seal, the date, the
	# party's numbers as labelled chips, and the screens as tablets
	var top := PanelContainer.new()
	_top_bar = top
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	top.add_theme_stylebox_override("panel", _banner_box())
	root.add_child(top)
	var row := UI.hbox(10)
	top.add_child(row)
	season_seal = UISkin.seal("冬", 44, UISkin.CINNABAR)
	row.add_child(season_seal)
	var dbox := UI.vbox(0)
	dbox.custom_minimum_size.x = 300
	row.add_child(dbox)
	date_label = UI.label("", 19, UISkin.GOLD_PALE)
	date_label.add_theme_font_override("font", UISkin.font("display"))
	dbox.add_child(date_label)
	top_label = UI.rich("", 330)
	top_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	top_label.add_theme_color_override("default_color", Color(0.92, 0.85, 0.72))
	top_label.add_theme_font_size_override("normal_font_size", UI.px(15))
	top_label.add_theme_font_size_override("italics_font_size", UI.px(15))
	dbox.add_child(top_label)
	# stats on the first line, the window buttons on the second, so the
	# larger text fits across the screen
	var right := UI.vbox(4)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var chips := UI.hbox(24)
	chips.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(chips)
	var buttons := UI.hbox(6)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(buttons)
	for k in [["gold", "Gold"], ["party", "Party"], ["wounded", "Wounded"], ["prisoners", "Captives"], ["food", "Food"], ["morale", "Morale"], ["renown", "Renown"], ["hp", "Health"]]:
		var cb := UI.vbox(0)
		var cap := UI.label(k[1].to_upper(), 11, Color(UISkin.GOLD, 0.9))
		cap.add_theme_font_override("font", UISkin.font("display_med"))
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cb.add_child(cap)
		var val := UI.label("", 18, Color(0.98, 0.93, 0.82))
		val.add_theme_font_override("font", UISkin.font("bold"))
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cb.add_child(val)
		chips.add_child(cb)
		hud_chips[k[0]] = val
	for b in [["Camp", "T", _open_camp], ["Party", "P", _open_party], ["Character", "C", _open_character],
			["Inventory", "I", _open_inventory], ["Quests", "J", _open_quests], ["Nations", "N", _open_factions]]:
		var tb := UI.button("%s %s" % [b[0], b[1]], b[2])
		tb.tooltip_text = "%s (%s)" % [b[0], b[1]]
		tb.add_theme_font_size_override("font_size", UI.px(16))
		for st in ["normal", "hover", "pressed"]:
			var bx: StyleBoxTexture = UISkin.button_box(st)
			bx.content_margin_left = 9
			bx.content_margin_right = 9
			tb.add_theme_stylebox_override(st, bx)
		buttons.add_child(tb)
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
	tc.add_theme_stylebox_override("panel", _banner_box())
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
	status_label = UI.label("", 16, Color(0.95, 0.88, 0.74))
	status_label.add_theme_font_override("font", UISkin.font("italic"))
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

## The HUD's lacquer band: dark red-brown with a gold rule along its edge.
func _banner_box() -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = Color(0.05, 0.045, 0.04, 0.9)
	b.border_color = UISkin.GOLD
	b.border_width_bottom = 2
	b.border_width_top = 2
	b.set_content_margin_all(8)
	b.content_margin_left = 14
	b.content_margin_right = 14
	b.shadow_color = Color(0, 0, 0, 0.35)
	b.shadow_size = 6
	return b

func _make_world_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UISkin.font("display"))
	l.add_theme_font_size_override("font_size", UI.px(size + 2))
	l.add_theme_color_override("font_color", Color(1, 0.96, 0.86))
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.03))
	l.add_theme_constant_override("outline_size", 6)
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
	var fid: String = GS.flags.get("story_fight", "")
	if fid != "" and not is_modal_open():
		GS.flags.erase("story_fight")
		if GS.parties.has(fid):
			GS.start_battle.call_deferred([fid])

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
	Story.fire("arrive", sid)
	open_settlement(sid)
	if Story.has_pending():
		open_dialogue(Story.pop_pending())

func open_dialogue(id: String) -> Control:
	if id == "" or not Story.has_dialogue(id):
		return null
	waiting = false
	GS.player_party().moving = false
	var w = DialogueWindow.new()
	w.dlg_id = id
	open_window(w)
	return w

## Story beats queued by the simulation appear when no window is open.
func _check_story() -> void:
	if is_modal_open():
		return
	if Story.has_pending():
		open_dialogue(Story.pop_pending())
	elif GS.flags.get("pending_epilogue", "") != "":
		var ew = EpilogueWindow.new()
		ew.kind = GS.flags.pending_epilogue
		GS.flags.pending_epilogue = ""
		open_window(ew)

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
	_check_story()
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
	MapBuilder.update_zoom(cam_dist)

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
	MapBuilder.set_daylight(0.35 + 0.65 * daylight)
	match MapBuilder.map_style():
		"chart": sky = Color(0.62, 0.6, 0.52).lerp(Color(0.8, 0.76, 0.64), daylight)
		"ink": sky = Color(0.6, 0.6, 0.58).lerp(Color(0.88, 0.88, 0.85), daylight)
		"painted": sky = Color(0.08, 0.11, 0.12).lerp(Color(0.2, 0.28, 0.3), daylight)
	env.background_color = sky
	env.fog_light_color = sky.lightened(0.15)
	env.fog_density = clampf(0.1 / cam_dist, 0.00015, 0.0015)
	sun.rotation_degrees.x = -25.0 - daylight * 40.0

func _player_sight() -> float:
	return SIGHT + GS.skill("spotting") * 4.0

## Parties resting inside a friendly settlement, as in Warband: they are in
## the hall or the barracks, not standing on the walls. Refreshed four times a
## second; id -> settlement id.
var _sheltered := {}
var _sheltered_t := 0.0

func _refresh_sheltered() -> void:
	_sheltered = {}
	for id in GS.parties:
		var p: Dictionary = GS.parties[id]
		if id == "player" or not p.kind in ["lord", "caravan", "villager"] or p.get("besieging", "") != "":
			continue
		if p.moving and GS.hours >= p.get("wait_until", 0.0):
			continue
		for sid in Data.settlements:
			if Data.settlements[sid].pos.distance_to(p.pos) < GS.shelter_radius(sid):
				var f: String = GS.settlements[sid].faction
				if f == p.faction or not GS.at_war(f, p.faction):
					_sheltered[id] = sid
				break

func _update_parties(delta: float) -> void:
	var pp: Dictionary = GS.player_party()
	var sight := _player_sight()
	_sheltered_t -= delta
	if _sheltered_t <= 0.0:
		_sheltered_t = 0.25
		_refresh_sheltered()
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
		if _sheltered.has(id):
			visible_now = false
		node.visible = visible_now
		var target := Vector3(p.pos.x, Terrain.surface(p.pos), p.pos.y)
		var old := node.position
		node.position = old.lerp(target, minf(1.0, delta * 10.0))
		var mv := Vector2(target.x - old.x, target.z - old.z)
		if mv.length() > 0.01:
			node.rotation.y = lerp_angle(node.rotation.y, atan2(mv.x, mv.y), minf(1.0, delta * 8.0))
		var boat := node.get_node_or_null("Boat")
		if boat:
			boat.visible = Terrain.height(p.pos) < 0.0
		var body := node.get_node_or_null("Body")
		if body and p.kind == "pilgrim":
			body.position.y = 7.0 + sin(Time.get_ticks_msec() / 600.0) * 0.6
		var actor = node.get_node_or_null("Actor")
		if actor:
			actor.speed = 1.4 if (p.moving and GS.hours >= p.get("wait_until", 0.0)) else 0.0
			actor.set_process(visible_now)

var _story_marks := {}
var _story_marks_t := 0.0

## Settlements where a story beat is waiting get a gold star on the map;
## teachers and other standing services do not.
func _refresh_story_marks() -> void:
	_story_marks = {}
	for sid in Data.settlements:
		for o in Story.settlement_options(sid):
			if not o.get("service", false):
				_story_marks[sid] = true
				break

func _update_labels() -> void:
	_story_marks_t -= get_process_delta_time()
	if _story_marks_t <= 0.0:
		_story_marks_t = 1.0
		_refresh_story_marks()
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
		var txt: String = ("★ " if _story_marks.has(sid) else "") + d.name
		if not s.siege.is_empty():
			txt += " (besieged)"
		elif s.looted_until > GS.hours:
			txt += " (looted)"
		if l.text != txt:
			l.text = txt
		var fc: Color = Data.factions.get(s.faction, Data.factions.neutral).color
		l.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if _story_marks.has(sid) else Color(1, 0.97, 0.88).lerp(fc.lightened(0.4), 0.45))
		l.position = sp - Vector2(l.size.x / 2.0, l.size.y)
	# Party labels for visible lords, the player and nearby parties
	for id in party_nodes:
		var node: Node3D = party_nodes[id]
		var p: Dictionary = GS.parties[id]
		var want: bool = node.visible and (p.kind in ["lord", "player", "pilgrim"] or cam_dist < 140.0)
		if want and not party_labels.has(id):
			party_labels[id] = _make_world_label("", 13)
		if not party_labels.has(id):
			continue
		var l: Label = party_labels[id]
		if not want:
			l.visible = false
			continue
		var wp := node.position + Vector3(0, 9.0 if p.kind == "pilgrim" else 4.2, 0)
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
		elif p.kind == "pilgrim":
			col = Color(1, 0.8, 0.4)
		l.add_theme_color_override("font_color", col)
		l.position = camera.unproject_position(wp) - Vector2(l.size.x / 2.0, l.size.y)
	_declutter()

## Nudge overlapping map labels apart so stacked armies stay readable, and
## keep them out from under the top bar.
func _declutter() -> void:
	var ls := []
	var top_h: float = _top_bar.size.y if _top_bar else 0.0
	for l in settlement_labels.values() + party_labels.values():
		if l.visible and l.position.y < top_h:
			l.visible = false
		if l.visible:
			ls.append(l)
	ls.sort_custom(func(a, b): return a.position.y > b.position.y)
	var placed := []
	for l in ls:
		var r := Rect2(l.position, l.size)
		var guard := 0
		var moved := true
		while moved and guard < 8:
			moved = false
			guard += 1
			for q in placed:
				if r.intersects(q.grow(-1.0)):
					r.position.y = q.position.y - r.size.y
					moved = true
		l.position = r.position
		if r.position.y < top_h:
			l.visible = false
		placed.append(r)

func _update_hud(captive: bool) -> void:
	var pl: Dictionary = GS.player
	var pp: Dictionary = GS.player_party()
	var food_days := GS.food_days()
	date_label.text = GS.date_string()
	var t := "[i]%s[/i]" % GS.moon_string()
	if GS.is_comet():
		t += "  ·  [color=#ff8a55]Great Comet[/color]"
	if GS.is_lunar_eclipse():
		t += "  ·  [color=#ff9090]Lunar eclipse[/color]"
	top_label.text = t
	var glyph: String = {"Winter": "冬", "Spring": "春", "Summer": "夏", "Autumn": "秋"}.get(GS.season(), "冬")
	if season_seal.get_meta("glyph", "") != glyph:
		var fresh := UISkin.seal(glyph, 44, UISkin.CINNABAR)
		fresh.set_meta("glyph", glyph)
		season_seal.replace_by(fresh)
		season_seal.queue_free()
		season_seal = fresh
	var warn := Color(1.0, 0.55, 0.45)
	var cream := Color(0.98, 0.93, 0.82)
	_chip("gold", str(pl.gold), Color(1.0, 0.85, 0.45))
	_chip("party", "%d/%d" % [GS.party_size(), GS.party_limit()], cream)
	_chip("wounded", str(Roster.wounded(pp.roster)), cream)
	_chip("prisoners", str(Roster.total(pp.prisoners)), cream)
	_chip("food", "%.1f days" % food_days, cream if food_days > 3 else warn)
	_chip("morale", str(int(pl.morale)), cream if pl.morale >= 35 else warn)
	_chip("renown", str(pl.renown), cream)
	_chip("hp", "%d/%d" % [pl.hp, GS.max_hp()], cream if pl.hp > GS.max_hp() * 0.35 else warn)
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
			cam_dist = minf(950.0, cam_dist * 1.14)
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
			KEY_M:
				if cam_dist < 500.0:
					cam_dist = 900.0
					follow_player = false
					cam_target = Vector3(Data.MAP_W / 2.0, 0, Data.MAP_H / 2.0 + 60.0)
				else:
					cam_dist = 90.0
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
	# A click on a settlement's name, or right on the settlement, means the
	# settlement, whoever is camped beside it.
	for sid in settlement_labels:
		var l: Label = settlement_labels[sid]
		if l.visible and Rect2(l.position, l.size).grow(4.0).has_point(screen):
			return {"type": "settlement", "id": sid}
	for sid in settlement_nodes:
		var wp0: Vector3 = settlement_nodes[sid].position + Vector3(0, 2, 0)
		if not camera.is_position_behind(wp0) and camera.unproject_position(wp0).distance_to(screen) < 14.0:
			return {"type": "settlement", "id": sid}
	for id in party_labels:
		var pl: Label = party_labels[id]
		if id != "player" and pl.visible and Rect2(pl.position, pl.size).grow(2.0).has_point(screen):
			return {"type": "party", "id": id}
	var best := {}
	var bd := 26.0
	for id in party_nodes:
		var n: Node3D = party_nodes[id]
		if not n.visible or id == "player":
			continue
		var wp := n.position + Vector3(0, 8.0 if GS.parties[id].kind == "pilgrim" else 1.5, 0)
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

func _chip(key: String, text: String, col: Color) -> void:
	var l: Label = hud_chips.get(key)
	if l != null:
		l.text = text
		l.add_theme_color_override("font_color", col)

## Log lines sit on a strip of ink with the message's colour as a margin mark.
func _add_log_line(text: String, color: Color) -> void:
	if log_box == null:
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", UI.px(15))
	l.add_theme_color_override("font_color", Color(0.97, 0.92, 0.82).lerp(color, 0.35))
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.05, 0.03, 0.62)
	bg.border_color = color
	bg.border_width_left = 3
	bg.set_content_margin_all(4)
	bg.content_margin_left = 10
	bg.set_corner_radius_all(2)
	l.add_theme_stylebox_override("normal", bg)
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
