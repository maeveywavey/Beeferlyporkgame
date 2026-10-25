extends RefCounted
## UI construction helpers and the shared parchment theme.

const PARCHMENT := Color(0.91, 0.86, 0.75)
const PARCHMENT_DARK := Color(0.82, 0.75, 0.6)
const INK := Color(0.17, 0.11, 0.06)
const BROWN := Color(0.45, 0.29, 0.15)
const BROWN_LIGHT := Color(0.6, 0.4, 0.2)
const RED := Color(0.62, 0.14, 0.1)
const GREEN := Color(0.2, 0.45, 0.2)
const BLUE := Color(0.18, 0.35, 0.6)
const GOLD := Color(0.85, 0.65, 0.2)

static var _theme: Theme

static func _box(bg: Color, border: Color, bw: int = 2, radius: int = 4, pad: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	return s

static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 17
	t.set_stylebox("panel", "PanelContainer", _box(PARCHMENT, BROWN, 3, 6, 14))
	t.set_stylebox("panel", "Panel", _box(PARCHMENT, BROWN, 3, 6, 14))
	t.set_color("font_color", "Label", INK)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_stylebox("normal", "Button", _box(BROWN, Color(0.3, 0.18, 0.08), 2, 4, 10))
	t.set_stylebox("hover", "Button", _box(BROWN_LIGHT, Color(0.3, 0.18, 0.08), 2, 4, 10))
	t.set_stylebox("pressed", "Button", _box(Color(0.32, 0.2, 0.1), Color(0.2, 0.1, 0.05), 2, 4, 10))
	t.set_stylebox("disabled", "Button", _box(Color(0.6, 0.55, 0.48), Color(0.45, 0.4, 0.35), 2, 4, 10))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), GOLD, 2, 4, 10))
	t.set_color("font_color", "Button", Color(0.98, 0.94, 0.85))
	t.set_color("font_hover_color", "Button", Color(1, 1, 0.9))
	t.set_color("font_pressed_color", "Button", Color(1, 0.9, 0.7))
	t.set_color("font_disabled_color", "Button", Color(0.35, 0.3, 0.25))
	t.set_stylebox("normal", "LineEdit", _box(Color(0.97, 0.94, 0.86), BROWN, 2, 3, 8))
	t.set_stylebox("focus", "LineEdit", _box(Color(1, 0.98, 0.92), GOLD, 2, 3, 8))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_color", "CheckBox", INK)
	t.set_color("font_hover_color", "CheckBox", INK)
	t.set_color("font_pressed_color", "CheckBox", INK)
	t.set_color("font_color", "OptionButton", Color(0.98, 0.94, 0.85))
	t.set_stylebox("normal", "OptionButton", _box(BROWN, Color(0.3, 0.18, 0.08), 2, 4, 10))
	t.set_stylebox("hover", "OptionButton", _box(BROWN_LIGHT, Color(0.3, 0.18, 0.08), 2, 4, 10))
	t.set_stylebox("panel", "TooltipPanel", _box(Color(0.15, 0.1, 0.06, 0.95), GOLD, 1, 3, 8))
	t.set_color("font_color", "TooltipLabel", Color(0.98, 0.94, 0.85))
	t.set_stylebox("background", "ProgressBar", _box(Color(0.25, 0.18, 0.12), Color(0.1, 0.06, 0.03), 1, 3, 0))
	t.set_stylebox("fill", "ProgressBar", _box(RED, Color(0, 0, 0, 0), 0, 3, 0))
	t.set_color("font_color", "ProgressBar", Color(1, 1, 1))
	t.set_stylebox("slider", "HSlider", _box(Color(0.35, 0.25, 0.15), Color(0.2, 0.1, 0.05), 1, 3, 2))
	t.set_stylebox("separator", "HSeparator", _box(BROWN, BROWN, 0, 0, 0))
	t.set_constant("separation", "HSeparator", 10)
	_theme = t
	return t

static func label(text: String, size: int = 17, color: Color = INK, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 200
	return l

static func title(text: String, size: int = 26) -> Label:
	var l := label(text, size, Color(0.35, 0.12, 0.05))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func rich(text: String, min_w: float = 400.0) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size.x = min_w
	r.text = text
	r.add_theme_color_override("default_color", INK)
	r.add_theme_font_size_override("normal_font_size", 17)
	r.add_theme_font_size_override("bold_font_size", 17)
	return r

static func button(text: String, cb: Callable, min_w: float = 0.0, enabled: bool = true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.x = min_w
	b.disabled = not enabled
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func():
		Sfx.play("click", -8.0)
		cb.call())
	return b

## A wide left-aligned button used for menu options (Mount & Blade style).
static func option(text: String, cb: Callable, enabled: bool = true) -> Button:
	var b := button(text, cb, 0.0, enabled)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b

static func vbox(sep: int = 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep: int = 6) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func grid(cols: int, hsep: int = 12, vsep: int = 4) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", hsep)
	g.add_theme_constant_override("v_separation", vsep)
	return g

static func sep() -> HSeparator:
	return HSeparator.new()

static func spacer(h: float = 8.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c

static func expand() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

static func scroll(min_h: float = 300.0) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.custom_minimum_size.y = min_h
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return s

static func bar(value: float, max_value: float, color: Color, w: float = 160.0, h: float = 14.0) -> ProgressBar:
	var p := ProgressBar.new()
	p.max_value = max_value
	p.value = value
	p.show_percentage = false
	p.custom_minimum_size = Vector2(w, h)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	p.add_theme_stylebox_override("fill", fill)
	return p

static func color_text(text: String, c: Color) -> String:
	return "[color=#%s]%s[/color]" % [c.to_html(false), text]

static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()
