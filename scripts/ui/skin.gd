extends RefCounted
## The interface's material language (docs/design.md §8):
## paper you could tear, lacquer you could chip, ink that pooled where the
## brush stopped, gold leaf that is slightly uneven. Every texture is
## generated here once and cached, so nothing is a flat colour block and the
## project needs no image files for its interface.

# The interface after PS2-era menus (the reference is Kengo's form editor):
# dark, slightly translucent panels with fine grain, a bronze border and steel
# corner caps; white serif titles over a red rule; menu entries on dark wood
# planks that light up as an amber bar when chosen; light text with a drop
# shadow. The old constant names are kept, with new meanings.
const PAPER := Color(0.92, 0.9, 0.85)            # light text and marks
const PAPER_SHADE := Color(0.06, 0.055, 0.05)    # panel body
const INK := Color(0.92, 0.9, 0.85)              # body text
const SEPIA := Color(0.86, 0.7, 0.42)            # headings
const LACQUER := Color(0.1, 0.09, 0.09)          # tablets, dark end
const LACQUER_HI := Color(0.24, 0.22, 0.21)      # tablets, light end
const LACQUER_LO := Color(0.05, 0.045, 0.045)
const GOLD := Color(0.62, 0.47, 0.26)            # bronze
const GOLD_PALE := Color(0.98, 0.8, 0.36)        # amber highlight
const CINNABAR := Color(0.72, 0.12, 0.08)        # the red rule and seals
const JADE := Color(0.32, 0.62, 0.45)
const INDIGO := Color(0.42, 0.55, 0.85)
const STEEL := Color(0.44, 0.48, 0.55)
const WOOD := Color(0.3, 0.19, 0.11)

static var _tex := {}
static var _fonts := {}

# ---------------------------------------------------------------------------
# Fonts (OFL: Alegreya, Alegreya SC, Atkinson Hyperlegible, Ma Shan Zheng;
# licences in assets/fonts/)
# ---------------------------------------------------------------------------
static func readable() -> bool:
	return bool(GS.settings.get("readable_font", false))

static func _load_font(path: String) -> Font:
	var f = load(path)
	if f is Font:
		return f
	var ff := FontFile.new()
	ff.load_dynamic_font(path)
	return ff

## A weight of a variable font, with lining figures (Alegreya's default
## old-style numerals make 0 read as o in stat lines).
static func _weight(base: Font, w: int) -> Font:
	var ts := TextServerManager.get_primary_interface()
	var fv := FontVariation.new()
	fv.base_font = base
	if w > 0:
		fv.variation_opentype = {ts.name_to_tag("wght"): w}
	fv.opentype_features = {ts.name_to_tag("lnum"): 1}
	return fv

static func font(kind: String) -> Font:
	var key := kind + ("_r" if readable() else "")
	if _fonts.has(key):
		return _fonts[key]
	var f: Font
	if readable() and kind in ["body", "bold", "italic"]:
		f = _load_font({"body": "res://assets/fonts/AtkinsonHyperlegible-Regular.ttf", "bold": "res://assets/fonts/AtkinsonHyperlegible-Bold.ttf",
			"italic": "res://assets/fonts/AtkinsonHyperlegible-Italic.ttf"}[kind])
	else:
		match kind:
			"body": f = _weight(_load_font("res://assets/fonts/Alegreya_wght.ttf"), 450)
			"bold": f = _weight(_load_font("res://assets/fonts/Alegreya_wght.ttf"), 700)
			"italic": f = _weight(_load_font("res://assets/fonts/Alegreya-Italic_wght.ttf"), 450)
			"display": f = _weight(_load_font("res://assets/fonts/AlegreyaSC-Bold.ttf"), 0)
			"display_med": f = _weight(_load_font("res://assets/fonts/AlegreyaSC-Medium.ttf"), 0)
			"seal": f = _load_font("res://assets/fonts/MaShanZheng-Regular.ttf")
			_: f = ThemeDB.fallback_font
	_fonts[key] = f
	return f

static func reset() -> void:
	_fonts.clear()

# ---------------------------------------------------------------------------
# Generated textures
# ---------------------------------------------------------------------------
static func _noise(seed_v: int, freq: float) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = freq
	n.fractal_octaves = 4
	return n

## A dark panel for 9-slice: grained near-black, a black outer line, a
## bronze border with a lit top edge, and a faint inner line.
static func panel_texture(edge: int = 18, rule: bool = true) -> ImageTexture:
	var key := "panel_%d_%s" % [edge, rule]
	if _tex.has(key):
		return _tex[key]
	var sz := 96
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var n := _noise(7, 0.08)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for y in sz:
		for x in sz:
			var v := n.get_noise_2d(x, y) * 0.5 + 0.5
			var c := PAPER_SHADE.lightened(v * 0.05 + rng.randf() * 0.025)
			c.a = 0.97
			var d := mini(mini(x, y), mini(sz - 1 - x, sz - 1 - y))
			if rule:
				if d == 0:
					c = Color(0, 0, 0, 1)
				elif d == 1 or d == 2:
					c = GOLD.lightened(0.2 if y < sz / 2 else 0.0).darkened(0.0 if d == 1 else 0.25)
				elif d == 3:
					c = Color(0, 0, 0, 0.95)
				elif d == 6:
					c = Color(GOLD, 0.35)
			img.set_pixel(x, y, c)
	var t2 := ImageTexture.create_from_image(img)
	_tex[key] = t2
	return t2

## A faint grain laid over large panels.
static func paper_tile() -> ImageTexture:
	if _tex.has("paper_tile"):
		return _tex.paper_tile
	var sz := 128
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for y in sz:
		for x in sz:
			img.set_pixel(x, y, Color(1, 1, 1, rng.randf() * 0.025))
	var t := ImageTexture.create_from_image(img)
	_tex.paper_tile = t
	return t

## Action buttons: dark gunmetal tablets with a bronze edge; the selected
## state is the amber bar.
static func lacquer(state: String) -> ImageTexture:
	var key := "lacquer_" + state
	if _tex.has(key):
		return _tex[key]
	var w := 64
	var h := 36
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var grain := _noise(23, 0.1)
	var top: Color = {"normal": LACQUER_HI, "hover": Color(0.34, 0.31, 0.28), "pressed": LACQUER_LO, "disabled": Color(0.16, 0.15, 0.15), "selected": Color(1.0, 0.86, 0.4)}[state]
	var bot: Color = {"normal": LACQUER, "hover": Color(0.16, 0.14, 0.13), "pressed": Color(0.12, 0.1, 0.1), "disabled": Color(0.1, 0.1, 0.1), "selected": Color(0.86, 0.55, 0.14)}[state]
	var line: Color = {"normal": GOLD, "hover": GOLD_PALE, "pressed": GOLD.darkened(0.3), "disabled": Color(0.3, 0.28, 0.26), "selected": Color(0.4, 0.22, 0.06)}[state]
	for y in h:
		for x in w:
			var t := float(y) / (h - 1)
			if state == "pressed":
				t = 1.0 - t
			var c := top.lerp(bot, t)
			c = c.darkened(grain.get_noise_2d(x * 0.3, y * 1.5) * 0.06)
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if d == 0:
				c = Color(0, 0, 0)
			elif d == 1:
				c = line.lightened(0.15) if y < h / 2 else line.darkened(0.2)
			elif d == 2 and y < h / 2:
				c = c.lightened(0.12)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_tex[key] = tex
	return tex

## Menu entries: dark wood planks with grain and worn ends; hovered or
## chosen, the plank becomes a bright amber bar.
static func row(state: String) -> ImageTexture:
	var key := "row_" + state
	if _tex.has(key):
		return _tex[key]
	var w := 128
	var h := 32
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var grain := _noise(41, 0.06)
	var knots := _noise(43, 0.02)
	for y in h:
		for x in w:
			var c: Color
			if state in ["hover", "pressed"]:
				var t := float(y) / (h - 1)
				c = Color(1.0, 0.88, 0.42).lerp(Color(0.9, 0.58, 0.14), t)
				if state == "pressed":
					c = c.darkened(0.15)
			else:
				var g := grain.get_noise_2d(x * 0.12, y * 2.2) * 0.5 + 0.5
				var k := knots.get_noise_2d(x * 1.0, y * 1.0)
				c = WOOD.lerp(WOOD.darkened(0.45), g * 0.7 + maxf(k, 0.0) * 0.6)
				# darker, worn ends like a plank in a frame
				var ends := minf(float(x), float(w - 1 - x)) / 18.0
				c = c.darkened((1.0 - clampf(ends, 0.0, 1.0)) * 0.35)
				c.a = 0.92
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if d == 0:
				c = Color(0, 0, 0, 0.9)
			elif d == 1 and y < 3:
				c = c.lightened(0.18)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_tex[key] = tex
	return tex

## The rule under titles: a red line that fades out to the right.
static func brush_rule() -> ImageTexture:
	if _tex.has("brush"):
		return _tex.brush
	var w := 512
	var h := 6
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in w:
		var a := clampf(1.0 - float(x) / w, 0.0, 1.0)
		for y in h:
			var c := Color(0, 0, 0, 0)
			if y == 2 or y == 3:
				c = Color(CINNABAR, a)
			elif y == 4:
				c = Color(0, 0, 0, a * 0.6)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_tex.brush = tex
	return tex

## Check boxes: a dark box with a bronze edge, and an amber tick.
static func check_icon(checked: bool) -> ImageTexture:
	var key := "check_%s" % checked
	if _tex.has(key):
		return _tex[key]
	var s := 22
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d := mini(mini(x, y), mini(s - 1 - x, s - 1 - y))
			var c := Color(0, 0, 0, 0)
			if d >= 2:
				c = Color(0.08, 0.07, 0.07)
			if d == 2:
				c = GOLD
			img.set_pixel(x, y, c)
	if checked:
		for i in 12:
			var x := 5 + i
			var y := 12 + (i if i < 4 else 0) - (0 if i < 4 else (i - 4))
			for k in 3:
				img.set_pixel(clampi(x, 0, s - 1), clampi(y + k - 1, 0, s - 1), GOLD_PALE)
	var tex := ImageTexture.create_from_image(img)
	_tex[key] = tex
	return tex

# ---------------------------------------------------------------------------
# Style boxes
# ---------------------------------------------------------------------------
static func panel_box(edge: int = 18, pad: int = 16, rule: bool = true) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = panel_texture(edge, rule)
	s.set_texture_margin_all(edge)
	s.set_content_margin_all(pad)
	return s

static func button_box(state: String) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = lacquer(state)
	s.set_texture_margin_all(6)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 5
	s.content_margin_bottom = 6
	return s

static func row_box(state: String) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = row(state)
	s.texture_margin_left = 6
	s.texture_margin_bottom = 2
	s.content_margin_left = 16
	s.content_margin_right = 8
	s.content_margin_top = 5
	s.content_margin_bottom = 6
	return s

static func flat(bg: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0, radius: int = 3, pad: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	return s

# ---------------------------------------------------------------------------
# Seals: a carved-stone stamp with a single character
# ---------------------------------------------------------------------------
## A round seal control: `glyph` in Ma Shan Zheng on a cinnabar disc.
static func seal(glyph: String, size: float = 40.0, col: Color = CINNABAR) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var r := size * 0.5
		var ctr := Vector2(r, r)
		c.draw_circle(ctr, r - 1.0, col)
		c.draw_arc(ctr, r - 3.5, 0.0, TAU, 48, Color(0, 0, 0, 0.6), 1.5, true)
		var f := font("seal")
		var fs := int(size * 0.62)
		var tw := f.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		c.draw_string(f, Vector2(r - tw * 0.5, r + fs * 0.36), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PAPER))
	return c
