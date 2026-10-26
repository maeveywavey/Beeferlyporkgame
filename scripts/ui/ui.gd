extends RefCounted
## UI construction helpers and the shared theme. The look (paper, lacquer,
## brush, seals) is generated in skin.gd; this file maps it onto controls.
## Menu choices are rows on paper, actions are lacquered tablets, headings
## are set in Alegreya SC, and body text in Alegreya (or Atkinson Hyperlegible
## when "Readable font" is on).

const UISkin = preload("res://scripts/ui/skin.gd")

const PARCHMENT := Color(0.94, 0.9, 0.81)
const PARCHMENT_DARK := Color(0.84, 0.77, 0.64)
const INK := Color(0.13, 0.09, 0.07)
const BROWN := Color(0.42, 0.22, 0.12)
const BROWN_LIGHT := Color(0.6, 0.4, 0.2)
const RED := Color(0.66, 0.16, 0.1)
const GREEN := Color(0.16, 0.42, 0.3)
const BLUE := Color(0.2, 0.33, 0.55)
const GOLD := Color(0.8, 0.6, 0.22)

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

## Rebuild the theme (after the readable-font or scale settings change).
static func reset_theme() -> void:
	_theme = null
	UISkin.reset()

static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = UISkin.font("body")
	t.default_font_size = 18
	# Panels: a framed sheet of paper
	t.set_stylebox("panel", "PanelContainer", UISkin.panel_box(18, 16))
	t.set_stylebox("panel", "Panel", UISkin.panel_box(18, 16))
	t.set_color("font_color", "Label", INK)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_font("normal_font", "RichTextLabel", UISkin.font("body"))
	t.set_font("bold_font", "RichTextLabel", UISkin.font("bold"))
	t.set_font("italics_font", "RichTextLabel", UISkin.font("italic"))
	t.set_font("bold_italics_font", "RichTextLabel", UISkin.font("bold"))
	# Action buttons: lacquered tablets with a gold inlay line
	for st in ["normal", "hover", "pressed", "disabled"]:
		t.set_stylebox(st, "Button", UISkin.button_box(st))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), UISkin.GOLD_PALE, 2, 4, 10))
	t.set_font("font", "Button", UISkin.font("display_med"))
	t.set_color("font_color", "Button", Color(0.98, 0.93, 0.8))
	t.set_color("font_hover_color", "Button", Color(1, 0.97, 0.86))
	t.set_color("font_pressed_color", "Button", UISkin.GOLD_PALE)
	t.set_color("font_disabled_color", "Button", Color(0.82, 0.78, 0.72))
	t.set_color("font_outline_color", "Button", Color(0.12, 0.03, 0.02, 0.6))
	t.set_constant("outline_size", "Button", 2)
	# Menu rows (UI.option): choices read as a list on paper, not a wall of buttons
	t.set_type_variation("OptionRow", "Button")
	for st in ["normal", "hover", "pressed"]:
		t.set_stylebox(st, "OptionRow", UISkin.row_box(st))
	t.set_stylebox("disabled", "OptionRow", UISkin.row_box("normal"))
	t.set_stylebox("focus", "OptionRow", UISkin.row_box("hover"))
	t.set_font("font", "OptionRow", UISkin.font("body"))
	t.set_color("font_color", "OptionRow", INK)
	t.set_color("font_hover_color", "OptionRow", Color(0.45, 0.08, 0.04))
	t.set_color("font_pressed_color", "OptionRow", UISkin.CINNABAR)
	t.set_color("font_focus_color", "OptionRow", Color(0.45, 0.08, 0.04))
	t.set_color("font_disabled_color", "OptionRow", Color(0.5, 0.45, 0.4))
	t.set_constant("outline_size", "OptionRow", 0)
	# Inputs
	t.set_stylebox("normal", "LineEdit", UISkin.flat(Color(1, 0.98, 0.93), BROWN, 1, 2, 8))
	t.set_stylebox("focus", "LineEdit", UISkin.flat(Color(1, 0.99, 0.95), UISkin.CINNABAR, 2, 2, 8))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("caret_color", "LineEdit", UISkin.CINNABAR)
	for ty in ["CheckBox", "CheckButton"]:
		t.set_color("font_color", ty, INK)
		t.set_color("font_hover_color", ty, INK)
		t.set_color("font_pressed_color", ty, INK)
	t.set_icon("checked", "CheckBox", UISkin.check_icon(true))
	t.set_icon("unchecked", "CheckBox", UISkin.check_icon(false))
	t.set_stylebox("normal", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckBox", StyleBoxEmpty.new())
	t.set_color("font_color", "OptionButton", Color(0.98, 0.93, 0.8))
	t.set_stylebox("normal", "OptionButton", UISkin.button_box("normal"))
	t.set_stylebox("hover", "OptionButton", UISkin.button_box("hover"))
	# Tooltips: ink on dark paper
	t.set_stylebox("panel", "TooltipPanel", UISkin.flat(Color(0.12, 0.08, 0.06, 0.96), UISkin.GOLD, 1, 2, 10))
	t.set_color("font_color", "TooltipLabel", Color(0.97, 0.92, 0.82))
	t.set_font("font", "TooltipLabel", UISkin.font("italic"))
	# Bars: an inset track and a fill with a lit top edge
	t.set_stylebox("background", "ProgressBar", UISkin.flat(Color(0.22, 0.15, 0.1), Color(0.1, 0.06, 0.03), 1, 2, 0))
	var fill := UISkin.flat(RED, RED.lightened(0.35), 0, 2, 0)
	fill.border_width_top = 1
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_color("font_color", "ProgressBar", Color(1, 1, 1))
	# Sliders and scrollbars
	t.set_stylebox("slider", "HSlider", UISkin.flat(Color(0.3, 0.2, 0.12), Color(0.15, 0.08, 0.04), 1, 3, 2))
	t.set_stylebox("grabber_area", "HSlider", UISkin.flat(UISkin.CINNABAR, Color(0, 0, 0, 0), 0, 3, 2))
	t.set_stylebox("grabber_area_highlight", "HSlider", UISkin.flat(UISkin.LACQUER_HI, Color(0, 0, 0, 0), 0, 3, 2))
	t.set_stylebox("scroll", "VScrollBar", UISkin.flat(Color(0.5, 0.38, 0.25, 0.18), Color(0, 0, 0, 0), 0, 3, 3))
	t.set_stylebox("grabber", "VScrollBar", UISkin.flat(Color(0.42, 0.22, 0.12, 0.75), Color(0, 0, 0, 0), 0, 3, 3))
	t.set_stylebox("grabber_highlight", "VScrollBar", UISkin.flat(UISkin.LACQUER_HI, Color(0, 0, 0, 0), 0, 3, 3))
	t.set_stylebox("grabber_pressed", "VScrollBar", UISkin.flat(UISkin.CINNABAR, Color(0, 0, 0, 0), 0, 3, 3))
	# Rules: a dry brush stroke
	var rule := StyleBoxTexture.new()
	rule.texture = UISkin.brush_rule()
	rule.content_margin_top = 3
	rule.content_margin_bottom = 3
	t.set_stylebox("separator", "HSeparator", rule)
	t.set_constant("separation", "HSeparator", 12)
	_theme = t
	return t

static func label(text: String, size: int = 17, color: Color = INK, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	# Section headings (larger, sepia) are set in small capitals
	if size >= 18 and color == BROWN:
		l.add_theme_font_override("font", UISkin.font("display_med"))
		l.add_theme_font_size_override("font_size", size + 1)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 200
	return l

static func title(text: String, size: int = 26) -> Label:
	var l := label(text, size, Color(0.38, 0.1, 0.05))
	l.add_theme_font_override("font", UISkin.font("display"))
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
	r.add_theme_font_size_override("normal_font_size", 18)
	r.add_theme_font_size_override("bold_font_size", 18)
	r.add_theme_font_size_override("italics_font_size", 18)
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
	b.theme_type_variation = "OptionRow"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
	fill.set_corner_radius_all(2)
	fill.border_width_top = 1
	fill.border_color = color.lightened(0.35)
	p.add_theme_stylebox_override("fill", fill)
	return p

## Show a button as the chosen one: gold leaf with ink lettering.
static func mark_selected(b: Button) -> void:
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, UISkin.button_box("selected"))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, Color(0.25, 0.06, 0.03))
	b.add_theme_constant_override("outline_size", 0)

static func color_text(text: String, c: Color) -> String:
	return "[color=#%s]%s[/color]" % [c.to_html(false), text]

static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()
