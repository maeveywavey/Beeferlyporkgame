extends Control
## Base modal window: a framed sheet of paper on a lamp-lit backdrop, a seal
## and a small-caps title, a brush rule, then the content. Windows settle in
## (a short fade and scale) unless reduced motion is on. Subclasses override
## build().

const UI = preload("res://scripts/ui/ui.gd")
const UISkin = preload("res://scripts/ui/skin.gd")

## One character stamped beside each window's title, by window type.
const SEALS := {"settlement_window.gd": "城", "dialogue_window.gd": "言", "camp_window.gd": "宿", "party_window.gd": "兵",
	"character_window.gd": "人", "inventory_window.gd": "包", "quest_window.gd": "卷", "faction_window.gd": "邦",
	"avatar_window.gd": "神", "forms_window.gd": "式", "techniques_window.gd": "法", "bending_work_window.gd": "工",
	"settings_window.gd": "律", "trade_window.gd": "市", "shop_window.gd": "器", "help_window.gd": "知",
	"epilogue_window.gd": "末", "garrison_window.gd": "守", "result_window.gd": "武", "encounter_window.gd": "遇"}

signal closed

var panel: PanelContainer
var content: VBoxContainer
var title_label: Label
var window_title := ""
var window_size := Vector2(720, 520)
var closable := true
var seal_glyph := ""

func _ready() -> void:
	theme = UI.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/ui_vignette.gdshader")
	dim.material = sm
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size = window_size
	panel.add_theme_stylebox_override("panel", UISkin.panel_box(22, 22))
	panel.draw.connect(_draw_ornaments)
	center.add_child(panel)
	var tile := TextureRect.new()
	tile.texture = UISkin.paper_tile()
	tile.stretch_mode = TextureRect.STRETCH_TILE
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tile)
	var outer := UI.vbox(6)
	panel.add_child(outer)
	var head := UI.hbox(12)
	outer.add_child(head)
	if seal_glyph == "":
		var sc = get_script()
		seal_glyph = SEALS.get(sc.resource_path.get_file() if sc != null else "", "")
	if seal_glyph != "":
		head.add_child(UISkin.seal(seal_glyph, 40))
	title_label = UI.title(window_title, 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title_label)
	if closable:
		head.add_child(_close_button())
	outer.add_child(UI.sep())
	content = UI.vbox(6)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(content)
	refresh()
	if not GS.settings.get("reduce_motion", false):
		panel.modulate.a = 0.0
		dim.modulate.a = 0.0
		panel.scale = Vector2(0.975, 0.975)
		_settle.call_deferred(dim)

func _settle(dim: Control) -> void:
	if not is_inside_tree():
		return
	panel.pivot_offset = panel.size * 0.5
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.16)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.2)
	tw.tween_property(dim, "modulate:a", 1.0, 0.2)

## A round lacquer stamp with a × in it.
func _close_button() -> Button:
	var b := UI.button("×", close, 40)
	b.custom_minimum_size = Vector2(40, 40)
	for st in ["normal", "hover", "pressed"]:
		var bx := UISkin.flat({"normal": UISkin.LACQUER, "hover": UISkin.LACQUER_HI, "pressed": UISkin.LACQUER_LO}[st], UISkin.GOLD, 2, 20, 0)
		b.add_theme_stylebox_override(st, bx)
	b.add_theme_font_size_override("font_size", 24)
	b.tooltip_text = "Close (Esc)"
	return b

## Gold corner brackets with a bead at each corner, inside the burnt edge.
func _draw_ornaments() -> void:
	var r := Rect2(Vector2.ZERO, panel.size).grow(-11.0)
	var g := Color(UISkin.GOLD, 0.95)
	var L := 30.0
	for k in 4:
		var c := Vector2(r.position.x if k % 2 == 0 else r.end.x, r.position.y if k < 2 else r.end.y)
		var sx := 1.0 if k % 2 == 0 else -1.0
		var sy := 1.0 if k < 2 else -1.0
		panel.draw_line(c, c + Vector2(L * sx, 0), g, 2.0)
		panel.draw_line(c, c + Vector2(0, L * sy), g, 2.0)
		panel.draw_line(c + Vector2(5 * sx, 5 * sy), c + Vector2(L * 0.6 * sx, 5 * sy), g, 1.0)
		panel.draw_line(c + Vector2(5 * sx, 5 * sy), c + Vector2(5 * sx, L * 0.6 * sy), g, 1.0)
		panel.draw_circle(c, 3.0, UISkin.CINNABAR)
		panel.draw_arc(c, 3.0, 0.0, TAU, 12, g, 1.0)

func set_title(t: String) -> void:
	window_title = t
	if title_label:
		title_label.text = t

func refresh() -> void:
	UI.clear(content)
	build()

## Override in subclasses.
func build() -> void:
	pass

func close() -> void:
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if closable and event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()
