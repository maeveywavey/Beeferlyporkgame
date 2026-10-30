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

## Open windows, oldest first: only the topmost answers keys.
static var _stack: Array = []

func _is_top() -> bool:
	while not _stack.is_empty() and not is_instance_valid(_stack[-1]):
		_stack.pop_back()
	return not _stack.is_empty() and _stack[-1] == self

func _ready() -> void:
	_stack.append(self)
	tree_exiting.connect(func(): _stack.erase(self))
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
	# windows grow with the larger text, but never past the screen
	var room := get_viewport_rect().size - Vector2(40, 30) if is_inside_tree() else Vector2(1560, 870)
	panel.custom_minimum_size = (window_size * 1.3).min(room)
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
	# The content scrolls if the larger text makes it taller or wider than
	# the window can be on screen.
	var body := ScrollContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body.custom_minimum_size = panel.custom_minimum_size - Vector2(48, 110)
	outer.add_child(body)
	content = UI.vbox(6)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(content)
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
	b.add_theme_font_size_override("font_size", UI.px(24))
	b.tooltip_text = "Close (Esc)"
	return b

## Gold corner brackets with a bead at each corner, inside the burnt edge.
## Steel corner caps over the bronze border, bevelled like stamped metal.
func _draw_ornaments() -> void:
	var r := Rect2(Vector2.ZERO, panel.size)
	var s := 16.0
	for k in 4:
		var x := r.position.x if k % 2 == 0 else r.end.x - s
		var y := r.position.y if k < 2 else r.end.y - s
		var cap := Rect2(x, y, s, s)
		panel.draw_rect(cap, UISkin.STEEL.darkened(0.25))
		panel.draw_rect(Rect2(x + 2, y + 2, s - 4, s - 4), UISkin.STEEL)
		panel.draw_line(Vector2(x + 2, y + 2), Vector2(x + s - 2, y + 2), UISkin.STEEL.lightened(0.45), 1.0)
		panel.draw_line(Vector2(x + 2, y + 2), Vector2(x + 2, y + s - 2), UISkin.STEEL.lightened(0.3), 1.0)
		panel.draw_rect(cap, Color(0, 0, 0), false, 1.0)

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

## Every window's choice rows work like a conversation's: numbered, chosen
## with 1-9 (0 for a tenth), and Esc takes the way out when the window has no close button.
const LEAVE_WORDS := ["leave", "farewell", "back", "never mind", "cancel", "not now", "another time", "\"i'll go", "\"another time", "end conversation", "continue", "close", "done"]
var _number_t := 0.0

func _option_rows(n: Node = null, out: Array = []) -> Array:
	if n == null:
		n = content
	if n == null:
		return out
	for c in n.get_children():
		if c is Button and c.theme_type_variation == "OptionRow" and c.is_visible_in_tree():
			out.append(c)
		else:
			_option_rows(c, out)
	return out

static func _bare(text: String) -> String:
	var r := RegEx.create_from_string("^\\d\\.\\s+")
	return r.sub(text, "")

func _process(delta: float) -> void:
	_number_t -= delta
	if _number_t > 0.0:
		return
	_number_t = 0.2
	var rows := _option_rows()
	for i in mini(rows.size(), 10):
		var b: Button = rows[i]
		var want := "%d.  %s" % [(i + 1) % 10, _bare(b.text)]
		if b.text != want:
			b.text = want
			UI.fit_option(b)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo) or not _is_top():
		return
	var k: int = event.physical_keycode
	if k == KEY_ESCAPE:
		if closable:
			get_viewport().set_input_as_handled()
			close()
			return
		for b in _option_rows():
			var t := _bare(b.text).to_lower()
			for w in LEAVE_WORDS:
				if t.begins_with(w) and not b.disabled:
					get_viewport().set_input_as_handled()
					b.pressed.emit()
					return
		return
	if k >= KEY_0 and k <= KEY_9:
		var rows := _option_rows()
		var idx := 9 if k == KEY_0 else k - KEY_1
		if idx < rows.size() and not rows[idx].disabled:
			get_viewport().set_input_as_handled()
			rows[idx].pressed.emit()
