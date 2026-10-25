extends Control
## Title screen and character creation.

const UI = preload("res://scripts/ui/ui.gd")
const SettingsWindow = preload("res://scripts/ui/settings_window.gd")

var panel: PanelContainer
var body: VBoxContainer
var page := "title"
var c_name := "Lee"
var c_background := "ek_refugee"
var c_bend := ""
var c_skin := Color(0.87, 0.7, 0.55)
var c_hair := Color(0.12, 0.08, 0.05)
var note := ""

const SKINS := [Color(0.96, 0.84, 0.72), Color(0.87, 0.7, 0.55), Color(0.72, 0.53, 0.38), Color(0.55, 0.38, 0.25), Color(0.4, 0.27, 0.18)]
const HAIRS := [Color(0.08, 0.06, 0.05), Color(0.3, 0.18, 0.1), Color(0.55, 0.35, 0.18), Color(0.75, 0.75, 0.75)]

func _ready() -> void:
	Music.play("map")
	theme = UI.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.08, 0.06)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var emblem := Control.new()
	emblem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblem.draw.connect(_draw_emblem.bind(emblem))
	add_child(emblem)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 560)
	center.add_child(panel)
	body = UI.vbox(10)
	panel.add_child(body)
	_build()

func _draw_emblem(c: Control) -> void:
	var sz := c.size
	var cols := [Color(0.8, 0.25, 0.1, 0.18), Color(0.2, 0.5, 0.2, 0.18), Color(0.2, 0.45, 0.8, 0.18), Color(0.95, 0.85, 0.5, 0.18)]
	var pos := [Vector2(0.15, 0.25), Vector2(0.85, 0.25), Vector2(0.15, 0.78), Vector2(0.85, 0.78)]
	for i in 4:
		c.draw_circle(pos[i] * sz, minf(sz.x, sz.y) * 0.16, cols[i])
		c.draw_arc(pos[i] * sz, minf(sz.x, sz.y) * 0.18, 0, TAU, 64, Color(cols[i], 0.35), 3.0)

func _build() -> void:
	UI.clear(body)
	match page:
		"title": _build_title()
		"create": _build_create()

func _build_title() -> void:
	body.add_child(UI.spacer(10))
	body.add_child(UI.title("AVATAR: MOUNT & BEND", 40))
	body.add_child(UI.title("A tale of the Hundred Year War", 20))
	var intro := UI.rich("[center][i]Water. Earth. Fire. Air. Long ago, the four nations lived together in harmony. Then everything changed when the Fire Nation attacked.\n\nRaise an army, master your element, serve a nation or carve out your own realm — before Sozin's Comet returns.[/i][/center]", 700)
	body.add_child(intro)
	body.add_child(UI.spacer(10))
	var col := UI.vbox(8)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(col)
	var has_auto := GS.has_save(GS.AUTOSAVE_PATH)
	var has_save := GS.has_save(GS.SAVE_PATH)
	col.add_child(_menu_button("New Game", func():
		page = "create"
		_build()))
	col.add_child(_menu_button("Continue (autosave)", func(): _load(GS.AUTOSAVE_PATH), has_auto))
	col.add_child(_menu_button("Load Saved Game", func(): _load(GS.SAVE_PATH), has_save))
	col.add_child(_menu_button("Settings", func():
		var sw = SettingsWindow.new()
		add_child(sw)))
	col.add_child(_menu_button("Quit", func(): get_tree().quit()))
	if note != "":
		body.add_child(UI.rich("[center]%s[/center]" % note, 700))
	body.add_child(UI.rich("[center][font_size=13]A fan-made game. Avatar: The Last Airbender belongs to its creators.[/font_size][/center]", 700))

func _menu_button(text: String, cb: Callable, enabled: bool = true) -> Button:
	var b := UI.button(text, cb, 320, enabled)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 20)
	return b

func _load(path: String) -> void:
	if GS.load_game(path):
		get_tree().change_scene_to_file("res://scenes/world_map.tscn")
	else:
		note = "Could not load the save."
		_build()

func _build_create() -> void:
	body.add_child(UI.title("Who are you?", 30))
	var nrow := UI.hbox()
	body.add_child(nrow)
	nrow.add_child(UI.label("Name:", 18))
	var le := LineEdit.new()
	le.text = c_name
	le.custom_minimum_size.x = 260
	le.text_changed.connect(func(t): c_name = t)
	nrow.add_child(le)
	body.add_child(UI.label("Background", 20, UI.BROWN))
	var grid := UI.grid(3, 8, 8)
	body.add_child(grid)
	for bid in GS.BACKGROUNDS:
		var bd: Dictionary = GS.BACKGROUNDS[bid]
		var b := UI.button(bd.name, func():
			c_background = bid
			if not GS.BACKGROUNDS[bid].bends.has(c_bend):
				c_bend = ""
			_build(), 230)
		if bid == c_background:
			b.add_theme_color_override("font_color", UI.GOLD)
			b.add_theme_color_override("font_hover_color", UI.GOLD)
		grid.add_child(b)
	var bd2: Dictionary = GS.BACKGROUNDS[c_background]
	body.add_child(UI.rich("[i]%s[/i]\nStarts at: [b]%s[/b]" % [bd2.desc, Data.settlements[bd2.start].name], 700))
	body.add_child(UI.label("Bending", 20, UI.BROWN))
	var brow := UI.hbox()
	body.add_child(brow)
	for e in bd2.bends:
		var label := "Non-bender (better with weapons)" if e == "" else Data.element_name(e)
		var b2 := UI.button(label, func():
			c_bend = e
			_build())
		if e == c_bend:
			b2.add_theme_color_override("font_color", UI.GOLD)
			b2.add_theme_color_override("font_hover_color", UI.GOLD)
		brow.add_child(b2)
	var looks := UI.hbox(8)
	body.add_child(looks)
	looks.add_child(UI.label("Skin:", 16))
	for c in SKINS:
		looks.add_child(_swatch(c, c == c_skin, func():
			c_skin = c
			_build()))
	looks.add_child(UI.label("   Hair:", 16))
	for c in HAIRS:
		looks.add_child(_swatch(c, c == c_hair, func():
			c_hair = c
			_build()))
	body.add_child(UI.spacer(6))
	var row := UI.hbox()
	body.add_child(row)
	row.add_child(UI.button("Back", func():
		page = "title"
		_build(), 120))
	row.add_child(UI.expand())
	row.add_child(UI.button("Begin your journey", _start, 240))

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
	var p := GS.create_player(nm, c_background, c_bend, c_skin, c_hair)
	GS.new_game(p)
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")
