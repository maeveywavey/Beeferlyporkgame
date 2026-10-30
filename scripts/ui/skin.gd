extends RefCounted
## The interface's material language (docs/design.md §8):
## paper you could tear, lacquer you could chip, ink that pooled where the
## brush stopped, gold leaf that is slightly uneven. Every texture is
## generated here once and cached, so nothing is a flat colour block and the
## project needs no image files for its interface.

const PAPER := Color(0.94, 0.9, 0.81)
const PAPER_SHADE := Color(0.84, 0.77, 0.64)
const INK := Color(0.13, 0.09, 0.07)
const SEPIA := Color(0.42, 0.22, 0.12)
const LACQUER := Color(0.4, 0.1, 0.07)
const LACQUER_HI := Color(0.56, 0.15, 0.09)
const LACQUER_LO := Color(0.24, 0.06, 0.04)
const GOLD := Color(0.83, 0.65, 0.3)
const GOLD_PALE := Color(0.95, 0.85, 0.6)
const CINNABAR := Color(0.7, 0.17, 0.1)
const JADE := Color(0.18, 0.45, 0.34)
const INDIGO := Color(0.2, 0.33, 0.55)

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

## A framed sheet of paper for 9-slice panels: mottled centre, burnt edge,
## an ink rule and a gold hairline inside it.
static func panel_texture(edge: int = 18, rule: bool = true) -> ImageTexture:
	var key := "panel_%d_%s" % [edge, rule]
	if _tex.has(key):
		return _tex[key]
	var sz := 128
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var n := _noise(7, 0.035)
	var fib := _noise(19, 0.4)
	for y in sz:
		for x in sz:
			var v := n.get_noise_2d(x, y) * 0.5 + 0.5
			var f2 := fib.get_noise_2d(x * 0.25, y * 3.0) * 0.5 + 0.5
			var c := PAPER.lerp(PAPER_SHADE, clampf(v * 0.55 + f2 * 0.15, 0.0, 1.0) * 0.55)
			var d := mini(mini(x, y), mini(sz - 1 - x, sz - 1 - y))
			if d < edge:
				var t := 1.0 - float(d) / edge
				c = c.lerp(Color(0.6, 0.46, 0.3), t * t * 0.75)
			if rule:
				if d == 3 or d == 4:
					c = c.lerp(INK, 0.85)
				elif d == 7:
					c = c.lerp(GOLD, 0.8)
			img.set_pixel(x, y, c)
	var t2 := ImageTexture.create_from_image(img)
	_tex[key] = t2
	return t2

## A tileable paper texture for large backgrounds.
static func paper_tile() -> ImageTexture:
	if _tex.has("paper_tile"):
		return _tex.paper_tile
	var sz := 256
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var n := _noise(3, 0.02)
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var fib := _noise(11, 0.25)
	for y in sz:
		for x in sz:
			# periodic sampling on a torus makes the tile seamless
			var ax := TAU * x / sz
			var ay := TAU * y / sz
			var v := n.get_noise_3d(cos(ax) * 40.0, sin(ax) * 40.0, cos(ay) * 40.0 + sin(ay) * 17.0) * 0.5 + 0.5
			var f2 := fib.get_noise_3d(cos(ax) * 10.0, sin(ax) * 10.0, sin(ay) * 90.0) * 0.5 + 0.5
			img.set_pixel(x, y, Color(1, 1, 1, 0).lerp(Color(0.55, 0.42, 0.28, 1.0), clampf((v - 0.5) * 0.35 + (f2 - 0.5) * 0.18 + 0.08, 0.0, 0.25)))
	var t := ImageTexture.create_from_image(img)
	_tex.paper_tile = t
	return t

## Lacquered wood tablets for buttons, in four states.
static func lacquer(state: String) -> ImageTexture:
	var key := "lacquer_" + state
	if _tex.has(key):
		return _tex[key]
	var w := 64
	var h := 36
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var grain := _noise(23, 0.08)
	var top: Color = {"normal": LACQUER_HI, "hover": Color(0.7, 0.22, 0.12), "pressed": LACQUER_LO, "disabled": Color(0.55, 0.5, 0.46), "selected": Color(1.0, 0.9, 0.6)}[state]
	var bot: Color = {"normal": LACQUER, "hover": LACQUER_HI, "pressed": Color(0.3, 0.08, 0.05), "disabled": Color(0.45, 0.41, 0.38), "selected": Color(0.78, 0.58, 0.26)}[state]
	var line: Color = {"normal": GOLD, "hover": GOLD_PALE, "pressed": GOLD.darkened(0.3), "disabled": Color(0.62, 0.58, 0.52), "selected": LACQUER}[state]
	for y in h:
		for x in w:
			var t := float(y) / (h - 1)
			if state == "pressed":
				t = 1.0 - t
			var c := top.lerp(bot, t)
			c = c.darkened(grain.get_noise_2d(x * 0.15, y * 2.5) * 0.08)
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if d == 0:
				c = Color(0.1, 0.03, 0.02)
			elif d == 1 and y < h / 2:
				c = c.lightened(0.18)    # lacquer catches the light on the top edge
			elif d == 3:
				c = c.lerp(line, 0.75)
			img.set_pixel(x, y, c)
	# rounded corners
	for p in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		img.set_pixelv(p, Color(0, 0, 0, 0))
	var tex := ImageTexture.create_from_image(img)
	_tex[key] = tex
	return tex

## Menu rows: text on paper, an ink rule beneath, a cinnabar tick on hover.
static func row(state: String) -> ImageTexture:
	var key := "row_" + state
	if _tex.has(key):
		return _tex[key]
	var w := 64
	var h := 32
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := Color(0, 0, 0, 0)
			match state:
				"hover":
					c = Color(0.62, 0.38, 0.2, 0.16 * (1.0 - float(x) / w) + 0.05)
				"pressed":
					c = Color(0.55, 0.3, 0.15, 0.28)
			if y == h - 1 and (x % 3) != 2:
				c = c.blend(Color(INK, 0.22))
			if x < 4 and state in ["hover", "pressed"] and y > 3 and y < h - 4:
				c = CINNABAR
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_tex[key] = tex
	return tex

## A brush stroke: thick in the middle, dry at the ends.
static func brush_rule() -> ImageTexture:
	if _tex.has("brush"):
		return _tex.brush
	var w := 512
	var h := 8
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var n := _noise(31, 0.05)
	for x in w:
		var t := float(x) / (w - 1)
		var thick := sin(t * PI) * 3.2 + 0.6
		for y in h:
			var dy := absf(y - h * 0.5 + 0.5)
			var a := clampf(thick - dy, 0.0, 1.0)
			var dry := n.get_noise_2d(x * 1.0, y * 6.0)
			if dry > 0.35 - t * 0.2 and (t < 0.15 or t > 0.85):
				a *= 0.2
			img.set_pixel(x, y, Color(INK, a * 0.85))
	var tex := ImageTexture.create_from_image(img)
	_tex.brush = tex
	return tex

## Simple check-box marks: an ink square, and the same with a brush tick.
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
				c = Color(1, 0.98, 0.92)
			if d == 2 or d == 3:
				c = INK
			img.set_pixel(x, y, c)
	if checked:
		for i in 12:
			var x := 5 + i
			var y := 12 + (i if i < 4 else 0) - (0 if i < 4 else (i - 4))
			for k in 3:
				img.set_pixel(clampi(x, 0, s - 1), clampi(y + k - 1, 0, s - 1), CINNABAR)
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
		c.draw_arc(ctr, r - 3.5, 0.0, TAU, 48, Color(PAPER, 0.85), 1.5, true)
		var f := font("seal")
		var fs := int(size * 0.62)
		var tw := f.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		c.draw_string(f, Vector2(r - tw * 0.5, r + fs * 0.36), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, PAPER))
	return c
