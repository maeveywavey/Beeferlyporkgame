extends Control
## Title screen and character creation.

const UI = preload("res://scripts/ui/ui.gd")
const UISkin = preload("res://scripts/ui/skin.gd")
const SettingsWindow = preload("res://scripts/ui/settings_window.gd")

var panel: PanelContainer
var body: VBoxContainer
var center: CenterContainer
var scroll_root: MarginContainer
var scroll_panel: PanelContainer
var scroll_body: VBoxContainer
var page := "title"
var c_name := "Lee"
var c_background := "ek_refugee"
var c_bend := ""
var c_skin := Color(0.87, 0.7, 0.55)
var c_hair := Color(0.12, 0.08, 0.05)
var c_body := "m"
var c_pronouns := "they"
var c_hair_style := "Hair_SimpleParted"
var c_beard := false
var c_era := "quiet"
var note := ""
var _preview_vp: SubViewport
var _preview_actor

const SKINS := [Color(0.96, 0.84, 0.72), Color(0.87, 0.7, 0.55), Color(0.72, 0.53, 0.38), Color(0.55, 0.38, 0.25), Color(0.4, 0.27, 0.18)]
const HAIRS := [Color(0.08, 0.06, 0.05), Color(0.3, 0.18, 0.1), Color(0.55, 0.35, 0.18), Color(0.75, 0.75, 0.75)]
const HAIR_STYLES := [["Hair_SimpleParted", "Parted"], ["Hair_Long", "Long"], ["Hair_Buns", "Buns"], ["Hair_Buzzed", "Cropped"], ["Hair_BuzzedFemale", "Short"], ["", "Shaved"]]
const PRONOUNS := [["he", "he/him"], ["she", "she/her"], ["they", "they/them"]]
const Actor = preload("res://scripts/actors/actor.gd")
const AvatarSys = preload("res://scripts/core/avatar.gd")
const ELEMENTS := [["", "Non-bender", "Better with weapons; no chi to run out of."], ["fire", "Firebender", "Breath and drive. Stronger by day."],
	["water", "Waterbender", "Flow and redirection. Stronger by night and moon."], ["earth", "Earthbender", "Root and patience. Strong anywhere there is ground."],
	["air", "Airbender", "Evasion and circles. Born to the Air Nomads, who ask you not to kill."]]

func _ready() -> void:
	Music.play("map")
	theme = UI.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# An ink-wash landscape, painted live (shaders/ink_wash.gdshader)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/ink_wash.gdshader")
	bg.material = sm
	add_child(bg)
	# Title page: a hanging scroll on the left
	scroll_root = MarginContainer.new()
	scroll_root.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	scroll_root.offset_right = 640
	for side in ["left", "top", "bottom"]:
		scroll_root.add_theme_constant_override("margin_" + side, 56 if side == "left" else 48)
	add_child(scroll_root)
	scroll_panel = PanelContainer.new()
	var sp: StyleBoxTexture = UISkin.panel_box(22, 30)
	sp.modulate_color = Color(1, 1, 1, 0.93)
	scroll_panel.add_theme_stylebox_override("panel", sp)
	scroll_root.add_child(scroll_panel)
	# the title menu scrolls if the larger text makes it taller than the screen
	var ts := ScrollContainer.new()
	ts.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_panel.add_child(ts)
	scroll_body = UI.vbox(10)
	scroll_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ts.add_child(scroll_body)
	# Creation pages: a centred sheet
	center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(1300, 820)
	panel.add_theme_stylebox_override("panel", UISkin.panel_box(22, 24))
	center.add_child(panel)
	var bs := ScrollContainer.new()
	bs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bs.custom_minimum_size = Vector2(1250, 770)
	panel.add_child(bs)
	body = UI.vbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bs.add_child(body)
	_build()

func _build() -> void:
	UI.clear(body)
	UI.clear(scroll_body)
	scroll_root.visible = page == "title"
	center.visible = page != "title"
	if page != "create" and _preview_actor != null:
		_preview_actor.queue_free()
		_preview_actor = null
	match page:
		"title": _build_title()
		"world": _build_world()
		"create": _build_create()

func _build_title() -> void:
	var b := scroll_body
	var seals := UI.hbox(10)
	seals.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(seals)
	for e in [["水", UISkin.INDIGO], ["土", UISkin.JADE], ["火", UISkin.CINNABAR], ["空", Color(0.85, 0.6, 0.2)]]:
		seals.add_child(UISkin.seal(e[0], 46, e[1]))
	var t := UI.title("Mount & Bend", 50)
	t.add_theme_color_override("font_color", Color(0.97, 0.96, 0.92))
	b.add_child(t)
	var st := UI.label("The Quiet Years, and after", 20, UI.BROWN)
	st.add_theme_font_override("font", UISkin.font("italic"))
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(st)
	b.add_child(UI.sep())
	b.add_child(UI.rich("[i]Water. Earth. Fire. Air. You are not the Avatar. You are one of the millions who live in the world the Avatar is trying to keep in balance.\n\nRaise an army, master your element, serve a nation or carve out your own realm. Rule well and the Avatar may come to sit at your table. Rule cruelly and they will come for you.[/i]", 420))
	b.add_child(UI.spacer(6))
	var has_auto := GS.has_save(GS.AUTOSAVE_PATH)
	var has_save := GS.has_save(GS.SAVE_PATH)
	b.add_child(_menu_button("New Game", func():
		page = "world"
		_build()))
	b.add_child(_menu_button("Continue (autosave)", func(): _load(GS.AUTOSAVE_PATH), has_auto))
	b.add_child(_menu_button("Load Saved Game", func(): _load(GS.SAVE_PATH), has_save))
	b.add_child(_menu_button("Settings", func():
		var sw = SettingsWindow.new()
		add_child(sw)))
	b.add_child(_menu_button("Quit", func(): get_tree().quit()))
	if note != "":
		b.add_child(UI.rich("[center]%s[/center]" % note, 420))
	b.add_child(UI.expand())
	b.add_child(UI.rich("[center][font_size=13]A fan-made game. Avatar: The Last Airbender belongs to its creators.[/font_size][/center]", 420))

func _menu_button(text: String, cb: Callable, enabled: bool = true) -> Button:
	var b := UI.option(text, cb, enabled)
	b.add_theme_font_override("font", UISkin.font("display_med"))
	b.add_theme_font_size_override("font_size", UI.px(25))
	return b

func _load(path: String) -> void:
	if GS.load_game(path):
		get_tree().change_scene_to_file("res://scenes/world_map.tscn")
	else:
		note = "Could not load the save."
		_build()

## Step one: which age of the world. The player is never the Avatar; in every
## era the Avatar is somebody else, living their own life.
func _build_world() -> void:
	body.add_child(UI.title("Choose your world", 30))
	body.add_child(UI.rich("[center][i]You are never the Avatar. In every era the Avatar is someone else: a person in the world, hard to find, who comes to you only for good reason.[/i][/center]", 860))
	var grid := UI.grid(2, 10, 10)
	body.add_child(grid)
	for e in ["quiet", "young", "prime", "elder"]:
		var info: Dictionary = AvatarSys.ERAS[e]
		var card := UI.vbox(4)
		card.custom_minimum_size = Vector2(420, 150)
		var b := UI.button(info.name + ("  (story)" if info.story else "  (sandbox)"), func():
			c_era = e
			_build(), 410)
		if e == c_era:
			UI.mark_selected(b)
		card.add_child(b)
		card.add_child(UI.rich("[font_size=14]%s[/font_size]" % info.pitch, 410))
		grid.add_child(card)
	body.add_child(UI.spacer(6))
	var row := UI.hbox()
	body.add_child(row)
	row.add_child(UI.button("Back", func():
		page = "title"
		_build(), 120))
	row.add_child(UI.expand())
	row.add_child(UI.button("Next: who you are", func():
		page = "create"
		_build(), 240))

## Step two: element first, then a background that fits it, then a face.
func _build_create() -> void:
	body.add_child(UI.title("Who are you?", 28))
	var nrow := UI.hbox()
	body.add_child(nrow)
	nrow.add_child(UI.label("Name:", 18))
	var le := LineEdit.new()
	le.text = c_name
	le.custom_minimum_size.x = 260
	le.text_changed.connect(func(t): c_name = t)
	nrow.add_child(le)
	nrow.add_child(UI.expand())
	nrow.add_child(UI.label(AvatarSys.ERAS[c_era].name, 16, UI.BROWN))
	body.add_child(UI.label("Bending", 20, UI.BROWN))
	var brow := UI.hbox(6)
	body.add_child(brow)
	for el in ELEMENTS:
		var b2 := UI.button(el[1], func():
			c_bend = el[0]
			if not GS.BACKGROUNDS[c_background].bends.has(c_bend):
				c_background = _backgrounds_for(c_bend)[0]
			_build(), 160)
		b2.tooltip_text = el[2]
		if el[0] == c_bend:
			UI.mark_selected(b2)
		brow.add_child(b2)
	for el in ELEMENTS:
		if el[0] == c_bend:
			body.add_child(UI.rich("[i]%s[/i]" % el[2], 860))
	body.add_child(UI.label("Background", 20, UI.BROWN))
	var grid := UI.grid(4, 8, 6)
	body.add_child(grid)
	for bid in _backgrounds_for(c_bend):
		var bd: Dictionary = GS.BACKGROUNDS[bid]
		var b := UI.button(bd.name, func():
			c_background = bid
			_build(), 205)
		if bid == c_background:
			UI.mark_selected(b)
		grid.add_child(b)
	var bd2: Dictionary = GS.BACKGROUNDS[c_background]
	body.add_child(UI.rich("[i]%s[/i]\nStarts at: [b]%s[/b]" % [bd2.desc, Data.settlements[bd2.start].name], 860))
	# Appearance and identity, with a live preview
	var arow := UI.hbox(24)
	body.add_child(arow)
	var acol := UI.vbox(6)
	arow.add_child(acol)
	acol.add_child(UI.label("Appearance", 20, UI.BROWN))
	var r1 := UI.hbox(6)
	acol.add_child(r1)
	r1.add_child(UI.label("Build:", 16))
	for bb in [["m", "Broader frame"], ["f", "Narrower frame"]]:
		r1.add_child(_choice_button(bb[1], c_body == bb[0], func():
			c_body = bb[0]
			if c_body == "f":
				c_beard = false
			_build()))
	var r2 := UI.hbox(6)
	acol.add_child(r2)
	r2.add_child(UI.label("Pronouns:", 16))
	for pp in PRONOUNS:
		r2.add_child(_choice_button(pp[1], c_pronouns == pp[0], func():
			c_pronouns = pp[0]
			_build()))
	var r3 := UI.hbox(6)
	acol.add_child(r3)
	r3.add_child(UI.label("Hair:", 16))
	for hs in HAIR_STYLES:
		r3.add_child(_choice_button(hs[1], c_hair_style == hs[0], func():
			c_hair_style = hs[0]
			_build()))
	if c_body == "m":
		r3.add_child(_choice_button("Beard", c_beard, func():
			c_beard = not c_beard
			_build()))
	var looks := UI.hbox(8)
	acol.add_child(looks)
	looks.add_child(UI.label("Skin:", 16))
	for c in SKINS:
		looks.add_child(_swatch(c, c == c_skin, func():
			c_skin = c
			_build()))
	looks.add_child(UI.label("   Hair colour:", 16))
	for c in HAIRS:
		looks.add_child(_swatch(c, c == c_hair, func():
			c_hair = c
			_build()))
	acol.add_child(UI.rich("[i]Build only chooses a body model. Pronouns are how the world refers to you; they open no doors and close none, except who might fall for you.[/i]", 600))
	arow.add_child(_preview())
	body.add_child(UI.spacer(4))
	var row := UI.hbox()
	body.add_child(row)
	row.add_child(UI.button("Back", func():
		page = "world"
		_build(), 120))
	row.add_child(UI.expand())
	row.add_child(UI.button("Begin your journey", _start, 240))

## Backgrounds open to a bender of `el` (every background allows non-benders).
func _backgrounds_for(el: String) -> Array:
	var out := []
	for bid in GS.BACKGROUNDS:
		if GS.BACKGROUNDS[bid].bends.has(el) or el == "":
			out.append(bid)
	return out

func _choice_button(text: String, sel: bool, cb: Callable) -> Button:
	var b := UI.button(text, cb)
	if sel:
		UI.mark_selected(b)
	return b

## A turning 3D preview of the character being created.
func _preview() -> Control:
	var box := SubViewportContainer.new()
	box.custom_minimum_size = Vector2(240, 300)
	box.stretch = true
	if _preview_vp == null:
		_preview_vp = SubViewport.new()
		_preview_vp.own_world_3d = true
		_preview_vp.size = Vector2i(240, 300)
		var we := WorldEnvironment.new()
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.09, 0.08, 0.075)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.9, 0.86, 0.8)
		env.ambient_light_energy = 0.55
		we.environment = env
		_preview_vp.add_child(we)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-30, 35, 0)
		_preview_vp.add_child(sun)
		var cam := Camera3D.new()
		cam.fov = 32.0
		cam.transform = Transform3D(Basis(), Vector3(0, 1.15, 3.6)).looking_at(Vector3(0, 0.95, 0), Vector3.UP)
		_preview_vp.add_child(cam)
	elif _preview_vp.get_parent() != null:
		_preview_vp.get_parent().remove_child(_preview_vp)
	box.add_child(_preview_vp)
	if _preview_actor != null:
		_preview_actor.queue_free()
	var culture: String = {"fn_deserter": "fire", "fn_noble": "fire", "swt_warrior": "south", "nwt_noble": "water", "hamakaze": "hamakaze",
		"air_nomad": "air", "temple_courier": "air"}.get(c_background, "earth")
	_preview_actor = Actor.new()
	_preview_actor.setup({"sex": c_body, "skin": c_skin, "hair": c_hair_style, "hair_color": c_hair, "beard": c_beard,
		"culture": culture, "outfit": "peasant", "kit": "air_robes" if culture == "air" else "", "accessory": ""})
	_preview_actor.set_stance("talk")
	_preview_actor.set_expression("happy")
	_preview_vp.add_child(_preview_actor)
	return box

func _process(delta: float) -> void:
	if _preview_actor != null and is_instance_valid(_preview_actor):
		_preview_actor.rotation.y += delta * 0.5

func _swatch(c: Color, sel: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(34, 34)
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_border_width_all(3 if sel else 1)
	sb.border_color = UI.GOLD if sel else Color(0.2, 0.1, 0.05)
	sb.set_corner_radius_all(4)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b

func _start() -> void:
	var nm := c_name.strip_edges()
	if nm == "":
		nm = "Lee"
	var p := GS.create_player(nm, c_background, c_bend, c_skin, c_hair, c_era)
	p.look.merge({"sex": c_body, "pronouns": c_pronouns, "hair_style": c_hair_style, "beard": c_beard}, true)
	GS.new_game(p)
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")
