extends RefCounted
## The battlefield's natural look: desaturated, textured ground; cliffs that
## jut from flat land; trees with modelled trunks and painted-card canopies;
## pines, bushes and grass as cards; and a painted mountain backdrop, as PS1
## games did it. Foliage grows in groves and along cliff feet rather than
## scattered evenly. Every texture is generated here at low resolution and
## cached per biome. The PS1 layer itself is in shaders/ps1.gdshaderinc.

const LIT = preload("res://shaders/lit.gdshader")
const SPRITE = preload("res://shaders/sprite.gdshader")
const BACKDROP = preload("res://shaders/backdrop.gdshader")
const BARK = preload("res://assets/nature/Bark_NormalTree.png")

static var _cache := {}

# ---------------------------------------------------------------------------
# Colours per biome, deliberately muted: [ground a, ground b, rock, foliage]
# ---------------------------------------------------------------------------
static func colours(biome: String) -> Dictionary:
	match biome:
		"desert", "beach": return {"g1": Color(0.66, 0.58, 0.44), "g2": Color(0.56, 0.47, 0.35), "rock": Color(0.62, 0.5, 0.38), "leaf": Color(0.42, 0.44, 0.3), "far": Color(0.7, 0.62, 0.52)}
		"snow": return {"g1": Color(0.86, 0.88, 0.9), "g2": Color(0.72, 0.75, 0.78), "rock": Color(0.45, 0.46, 0.48), "leaf": Color(0.22, 0.3, 0.26), "far": Color(0.7, 0.74, 0.8)}
		"volcanic": return {"g1": Color(0.3, 0.27, 0.25), "g2": Color(0.22, 0.2, 0.19), "rock": Color(0.26, 0.24, 0.23), "leaf": Color(0.3, 0.32, 0.24), "far": Color(0.36, 0.33, 0.33)}
		"swamp": return {"g1": Color(0.3, 0.33, 0.22), "g2": Color(0.24, 0.24, 0.17), "rock": Color(0.36, 0.37, 0.32), "leaf": Color(0.24, 0.32, 0.18), "far": Color(0.4, 0.44, 0.4)}
		"mountain", "highland": return {"g1": Color(0.4, 0.46, 0.28), "g2": Color(0.45, 0.4, 0.3), "rock": Color(0.47, 0.45, 0.42), "leaf": Color(0.24, 0.34, 0.2), "far": Color(0.42, 0.44, 0.46)}
		"forest": return {"g1": Color(0.3, 0.37, 0.2), "g2": Color(0.33, 0.3, 0.22), "rock": Color(0.45, 0.44, 0.4), "leaf": Color(0.22, 0.33, 0.17), "far": Color(0.45, 0.5, 0.52)}
	return {"g1": Color(0.38, 0.47, 0.24), "g2": Color(0.44, 0.4, 0.28), "rock": Color(0.5, 0.48, 0.43), "leaf": Color(0.27, 0.38, 0.2), "far": Color(0.42, 0.45, 0.47)}

static func _noise(seed: int, freq: float, octaves: int = 4) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed
	n.frequency = freq
	n.fractal_octaves = octaves
	return n

## A small seamless texture blending two colours by fractal noise, with fine
## speckle: soil and grass, or stone.
static func _blend_tex(key: String, a: Color, b: Color, size: int, seed: int, freq: float, speckle: float) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var n := _noise(seed, freq)
	var img: Image = n.get_seamless_image(size, size)
	img.convert(Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for y in size:
		for x in size:
			var v := img.get_pixel(x, y).r
			var c := a.lerp(b, smoothstep(0.35, 0.65, v))
			c = c.lightened(rng.randf() * speckle) if rng.randf() < 0.5 else c.darkened(rng.randf() * speckle)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t

## Large-scale brightness variation, centred on mid-grey.
static func _macro_tex() -> ImageTexture:
	if _cache.has("macro"):
		return _cache.macro
	var img: Image = _noise(77, 0.02, 3).get_seamless_image(64, 64)
	img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	_cache.macro = ImageTexture.create_from_image(img)
	return _cache.macro

static func lit_material(tex: Texture2D, projection: int, scale: float, saturation: float = 0.75, vertex_color: bool = true) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = LIT
	m.set_shader_parameter("detail_tex", tex)
	m.set_shader_parameter("macro_tex", _macro_tex())
	m.set_shader_parameter("proj_mode", projection)
	m.set_shader_parameter("detail_scale", scale)
	m.set_shader_parameter("saturation", saturation)
	m.set_shader_parameter("use_vertex_color", vertex_color)
	return m

static func ground_material(biome: String) -> ShaderMaterial:
	var c := colours(biome)
	var tex := _blend_tex("ground_" + biome, c.g1, c.g2, 128, 3, 0.06, 0.12)
	return lit_material(tex, 1, 0.22, 0.85)

static func rock_material(biome: String) -> ShaderMaterial:
	var c := colours(biome)
	var tex := _blend_tex("rock_" + biome, c.rock.lightened(0.12), c.rock.darkened(0.3), 128, 9, 0.09, 0.18)
	return lit_material(tex, 2, 0.3, 0.6)

# ---------------------------------------------------------------------------
# Painted cards
# ---------------------------------------------------------------------------
static func _disc(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(maxi(0, int(cy - ry)), mini(h, int(cy + ry) + 1)):
		for x in range(maxi(0, int(cx - rx)), mini(w, int(cx + rx) + 1)):
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, col)

## A clump of foliage: many small leaves, lit from the upper left.
static func leaf_card(biome: String, seed: int) -> ImageTexture:
	var key := "leaf_%s_%d" % [biome, seed]
	if _cache.has(key):
		return _cache[key]
	var base: Color = colours(biome).leaf
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in 420:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 27.0
		var x := 32.0 + cos(a) * r
		var y := 34.0 + sin(a) * r * 0.85
		# light from the upper left, darker inside the clump
		var lit := clampf(0.55 + (32.0 - x) * 0.008 + (34.0 - y) * 0.012 + (r / 27.0) * 0.25, 0.2, 1.1)
		var col := base * lit
		col = col.lerp(Color(0.5, 0.48, 0.3), rng.randf() * 0.15)
		col.a = 1.0
		_disc(img, x, y, rng.randf_range(1.5, 3.2), rng.randf_range(1.0, 2.2), col)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t

## A pine painted on a card: tiers of needles narrowing to the top.
static func pine_card(biome: String) -> ImageTexture:
	var key := "pine_" + biome
	if _cache.has(key):
		return _cache[key]
	var base: Color = colours(biome).leaf.darkened(0.15)
	var img := Image.create(64, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	_disc(img, 32, 116, 2.5, 12, Color(0.28, 0.2, 0.15))
	for tier in 7:
		var top := 6.0 + tier * 14.0
		var half := 6.0 + tier * 3.6
		for i in 160:
			var t := rng.randf()
			var y := top + t * 18.0
			var x := 32.0 + rng.randf_range(-1.0, 1.0) * half * (0.35 + t * 0.65)
			var lit := clampf(0.6 + (32.0 - x) * 0.012 - t * 0.25, 0.25, 1.4)
			var col := base * lit
			if snowy_biome(biome) and t < 0.25:
				col = Color(0.85, 0.88, 0.92)
			col.a = 1.0
			_disc(img, x, y, rng.randf_range(1.0, 2.0), 1.2, col)
	img.generate_mipmaps()
	var tx := ImageTexture.create_from_image(img)
	_cache[key] = tx
	return tx

static func snowy_biome(biome: String) -> bool:
	return biome == "snow"

## Grass or reeds: a tuft of blades.
static func grass_card(biome: String) -> ImageTexture:
	var key := "grass_" + biome
	if _cache.has(key):
		return _cache[key]
	var base: Color = colours(biome).leaf.lerp(colours(biome).g1, 0.4)
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 22:
		var x0 := rng.randf_range(6, 26)
		var lean := rng.randf_range(-0.5, 0.5)
		var h := rng.randf_range(12, 28)
		var col := base * rng.randf_range(0.75, 1.2)
		col.a = 1.0
		for k in int(h):
			var y := 31 - k
			var x := int(x0 + lean * k)
			if x >= 0 and x < 32:
				img.set_pixel(x, y, col.lightened(k / h * 0.25))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t

static func card(tex: Texture2D, size: Vector2, mode: int, light: Color) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	q.center_offset = Vector3(0, size.y * 0.5, 0)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	var m := ShaderMaterial.new()
	m.shader = SPRITE
	m.set_shader_parameter("image", tex)
	m.set_shader_parameter("billboard", mode)
	m.set_shader_parameter("light_tint", light)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

# ---------------------------------------------------------------------------
# Modelled pieces
# ---------------------------------------------------------------------------
## A tapered, slightly bent cylinder from a to b (low-poly, bark textured).
static func _limb(st: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float, sides: int = 6) -> void:
	var axis := (b - a).normalized()
	var side := axis.cross(Vector3.FORWARD if absf(axis.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var up := axis.cross(side).normalized()
	var length := a.distance_to(b)
	for i in sides:
		var t0 := TAU * i / sides
		var t1 := TAU * (i + 1) / sides
		var p := [a + (side * cos(t0) + up * sin(t0)) * r0, a + (side * cos(t1) + up * sin(t1)) * r0,
			b + (side * cos(t1) + up * sin(t1)) * r1, b + (side * cos(t0) + up * sin(t0)) * r1]
		var u0 := float(i) / sides
		var u1 := float(i + 1) / sides
		var uv := [Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, length * 0.5), Vector2(u0, length * 0.5)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_color(Color.WHITE)
			st.set_uv(uv[k])
			st.add_vertex(p[k])

## A broadleaf or dead tree: modelled trunk and branches, card canopy.
static func tree(biome: String, kind: String, rng: RandomNumberGenerator, light: Color) -> Node3D:
	var root := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := rng.randf_range(4.5, 7.5)
	var lean := Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
	var top := Vector3(0, h, 0) + lean
	_limb(st, Vector3.ZERO, top * 0.55, 0.32, 0.22)
	_limb(st, top * 0.55, top, 0.22, 0.1)
	var tips := [top]
	for i in rng.randi_range(3, 5):
		var at := top * rng.randf_range(0.45, 0.85)
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.4, 1.0), rng.randf_range(-1, 1)).normalized()
		var tip := at + dir * rng.randf_range(1.4, 2.6)
		_limb(st, at, tip, 0.12, 0.04, 5)
		tips.append(tip)
	st.generate_normals()
	var trunk := MeshInstance3D.new()
	trunk.mesh = st.commit()
	var bm := lit_material(BARK, 0, 1.0, 0.55, false)
	bm.set_shader_parameter("tint", Color(0.8, 0.75, 0.7) if kind != "dead" else Color(0.75, 0.72, 0.7))
	trunk.material_override = bm
	root.add_child(trunk)
	if kind == "dead":
		return root
	for tip in tips:
		for k in 2:
			var c := card(leaf_card(biome, rng.randi_range(1, 3)), Vector2.ONE * rng.randf_range(2.4, 3.6), 2, light)
			c.position = tip + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-1.2, 0.2), rng.randf_range(-0.6, 0.6))
			root.add_child(c)
	return root

static func pine(biome: String, rng: RandomNumberGenerator, light: Color) -> Node3D:
	var h := rng.randf_range(6.0, 10.0)
	return card(pine_card(biome), Vector2(h * 0.5, h), 1, light)

## A cliff or boulder: an irregular outcrop that narrows and breaks as it
## rises, with a tilted, jagged top, rock textured.
static func cliff(biome: String, radius: float, height: float, rng: RandomNumberGenerator) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := rng.randi_range(9, 13)
	var rows := 4
	var tilt := Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.25, 0.25))
	var shift := Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3)) * radius
	var base_r := []
	for i in n:
		base_r.append(radius * rng.randf_range(0.7, 1.2))
	var grid := []
	for row in rows + 1:
		var t := float(row) / rows
		var ring := []
		for i in n:
			var a := TAU * i / n
			# faces slope in, each row a little further, with breaks in the line
			var r: float = base_r[i] * lerpf(1.08, 0.55, pow(t, 0.8)) * rng.randf_range(0.88, 1.08)
			var c := Vector2(cos(a), sin(a)) * r + shift * t
			var y := -1.5 + (height + 1.5) * t * rng.randf_range(0.85, 1.1) + (c.x * tilt.x + c.y * tilt.y) * t
			ring.append(Vector3(c.x, y, c.y))
		grid.append(ring)
	for row in rows:
		for i in n:
			var j := (i + 1) % n
			var a0: Vector3 = grid[row][i]
			var b0: Vector3 = grid[row][j]
			var a1: Vector3 = grid[row + 1][i]
			var b1: Vector3 = grid[row + 1][j]
			for v in [a0, b0, b1, a0, b1, a1]:
				st.set_color(Color.WHITE)
				st.add_vertex(v)
	var cap := Vector3(shift.x, height * rng.randf_range(0.95, 1.1), shift.y)
	for i in n:
		var j := (i + 1) % n
		for v in [grid[rows][i], grid[rows][j], cap]:
			st.set_color(Color.WHITE)
			st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = rock_material(biome)
	return mi

## Mountains painted on a ring of cards around the field: three ranges,
## paler with distance, snow on the high ones.
static func backdrop(biome: String, sky: Color) -> Node3D:
	var root := Node3D.new()
	var c := colours(biome)
	for layer in 3:
		var tex := _range_tex(biome, layer, c.far.lerp(sky, 0.1 + layer * 0.22), sky)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var radius := 200.0 + layer * 45.0
		var height := 50.0 + layer * 22.0
		var segs := 48
		for i in segs:
			var a0 := TAU * i / segs
			var a1 := TAU * (i + 1) / segs
			var u0 := float(i) / segs * 2.0
			var u1 := float(i + 1) / segs * 2.0
			var p := [Vector3(cos(a0) * radius, -6.0, sin(a0) * radius), Vector3(cos(a1) * radius, -6.0, sin(a1) * radius),
				Vector3(cos(a1) * radius, height, sin(a1) * radius), Vector3(cos(a0) * radius, height, sin(a0) * radius)]
			var uv := [Vector2(u0, 1), Vector2(u1, 1), Vector2(u1, 0), Vector2(u0, 0)]
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_uv(uv[k])
				st.add_vertex(p[k])
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		var m := ShaderMaterial.new()
		m.shader = BACKDROP
		m.set_shader_parameter("image", tex)
		m.set_shader_parameter("billboard", 0)
		m.set_shader_parameter("cutoff", 0.5)
		m.set_shader_parameter("saturation", 0.75)
		mi.material_override = m
		root.add_child(mi)
	return root

static func _range_tex(biome: String, layer: int, col: Color, sky: Color) -> ImageTexture:
	var key := "range_%s_%d" % [biome, layer]
	if _cache.has(key):
		return _cache[key]
	var w := 512
	var h := 160
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ridge := _noise(100 + layer * 13, 0.011 + layer * 0.004, 5)
	var rock := _noise(7 + layer, 0.09, 3)
	var snowy := biome in ["snow", "mountain", "highland"] or layer == 2
	var snow_line := int(h * (0.42 if biome == "snow" else 0.26))
	for x in w:
		# seamless around the ring: sample the ridge on a circle
		var a := TAU * x / w
		var rv := ridge.get_noise_2d(cos(a) * 60.0, sin(a) * 60.0)
		var top := int(h * (0.6 - rv * 0.75 - layer * 0.1))
		top = clampi(top, 4, h - 6)
		var prev_a := TAU * (x - 1) / w
		var slope := rv - ridge.get_noise_2d(cos(prev_a) * 60.0, sin(prev_a) * 60.0)
		for y in range(top, h):
			var depth := float(y - top) / float(h - top)
			var shade := 0.85 + rock.get_noise_2d(x * 1.6, y * 1.2) * 0.22 + rock.get_noise_2d(x * 0.2, y * 6.0) * 0.08 + clampf(slope * 30.0, -0.22, 0.22)
			var cc := col * shade
			if snowy and top < snow_line and y < snow_line + int(rock.get_noise_2d(x * 3.0, 0.0) * 4.0):
				cc = Color(0.88, 0.9, 0.93) * (0.9 + shade * 0.1)
			cc = cc.lerp(sky, clampf(0.12 + depth * 0.2, 0.0, 0.3))
			cc.a = 1.0
			img.set_pixel(x, y, cc)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t

# ---------------------------------------------------------------------------
# Layout: groves and cliffs, not an even scatter
# ---------------------------------------------------------------------------
## Places of things for a battlefield: [{kind, pos (Vector2), r}]. The middle
## band where armies meet is kept mostly clear.
static func layout(biome: String, rng: RandomNumberGenerator, siege_z: float = 999.0) -> Array:
	var out := []
	# [groves, trees per grove, cliff groups]
	var amounts: Array = {"forest": [7, 14, 2], "swamp": [5, 10, 1], "desert": [1, 3, 5], "beach": [1, 3, 3],
		"snow": [3, 7, 4], "mountain": [3, 6, 6], "highland": [3, 6, 6], "volcanic": [3, 6, 6]}.get(biome, [4, 9, 3])
	var groves: int = amounts[0]
	var per: int = amounts[1]
	var cliffs: int = amounts[2]
	var clear := func(p: Vector2) -> bool:
		return absf(p.x) < 26.0 or absf(p.y - siege_z) < 12.0
	# cliffs jut from the flats at the flanks, sometimes in short ridges
	for i in cliffs:
		var side := -1.0 if i % 2 == 0 else 1.0
		var base := Vector2(side * rng.randf_range(34, 62), rng.randf_range(-40, 40))
		var dir := Vector2.from_angle(rng.randf() * TAU)
		for k in rng.randi_range(1, 3):
			var p := base + dir * k * rng.randf_range(5, 8)
			out.append({"kind": "cliff", "pos": p, "r": rng.randf_range(5.0, 9.0), "h": rng.randf_range(4.0, 9.0)})
			# boulders and scrub gather at the cliff foot
			for b in rng.randi_range(1, 3):
				out.append({"kind": "boulder", "pos": p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(6, 10), "r": rng.randf_range(0.8, 1.8)})
			for g in 6:
				out.append({"kind": "grass", "pos": p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(5, 11), "r": 0.0})
	# groves: trees bunched around a centre, undergrowth thick at the edges
	for i in groves:
		var c := Vector2(rng.randf_range(-68, 68), rng.randf_range(-40, 40))
		if clear.call(c):
			c.x = signf(c.x if c.x != 0.0 else 1.0) * rng.randf_range(30, 66)
		for k in per:
			var p := c + Vector2(rng.randfn(0.0, 5.0), rng.randfn(0.0, 4.0))
			if clear.call(p):
				continue
			out.append({"kind": "tree", "pos": p, "r": 0.5})
		for k in per * 2:
			var p2 := c + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(3, 11)
			out.append({"kind": "bush" if k % 3 == 0 else "grass", "pos": p2, "r": 0.0})
	# a few lone trees and tufts in the open
	for i in 4:
		var p3 := Vector2(rng.randf_range(-70, 70), rng.randf_range(-42, 42))
		if not clear.call(p3) and biome not in ["desert", "beach"]:
			out.append({"kind": "tree", "pos": p3, "r": 0.5})
	for i in 30:
		out.append({"kind": "grass", "pos": Vector2(rng.randf_range(-70, 70), rng.randf_range(-42, 42)), "r": 0.0})
	return out
