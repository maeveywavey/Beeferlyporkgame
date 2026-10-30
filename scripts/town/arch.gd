extends RefCounted
## Procedural architecture kit for walkable settlements. Builds whole
## buildings as single meshes with vertex colours (lit by
## shaders/building.gdshader), in the
## styles the original series drew: Earth Kingdom halls with green tile roofs
## and swept eaves, Fire Nation red-and-gold pagodas on black stone, Omashu's
## heavy mountain stone, Hamakaze timber, Water Tribe ice domes and Air Nomad
## towers with blue conical roofs.

const PAINT = preload("res://shaders/building.gdshader")

static var _mat_cache := {}

## Shared material: vertex colours do the painting.
static func material(outline: bool = true, emission: float = 0.0) -> ShaderMaterial:
	var key := "%s_%s" % [outline, emission]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := ShaderMaterial.new()
	m.shader = PAINT
	m.set_shader_parameter("emission_strength", emission)
	_mat_cache[key] = m
	return m

# ---------------------------------------------------------------------------
# Styles
# ---------------------------------------------------------------------------
const STYLES := {
	"earth": {"roof": Color(0.22, 0.46, 0.27), "ridge": Color(0.14, 0.3, 0.18), "wall": Color(0.9, 0.84, 0.7), "timber": Color(0.46, 0.3, 0.17),
		"plinth": Color(0.62, 0.59, 0.52), "door": Color(0.42, 0.26, 0.14), "lattice": Color(0.32, 0.2, 0.11), "accent": Color(0.85, 0.7, 0.3)},
	"omashu": {"roof": Color(0.33, 0.47, 0.2), "ridge": Color(0.42, 0.29, 0.5), "wall": Color(0.8, 0.76, 0.66), "timber": Color(0.5, 0.4, 0.3),
		"plinth": Color(0.56, 0.53, 0.49), "door": Color(0.38, 0.27, 0.42), "lattice": Color(0.3, 0.24, 0.2), "accent": Color(0.6, 0.45, 0.68)},
	"fire": {"roof": Color(0.56, 0.1, 0.07), "ridge": Color(0.86, 0.66, 0.2), "wall": Color(0.88, 0.81, 0.7), "timber": Color(0.62, 0.12, 0.08),
		"plinth": Color(0.24, 0.21, 0.21), "door": Color(0.2, 0.1, 0.08), "lattice": Color(0.18, 0.09, 0.07), "accent": Color(0.92, 0.72, 0.25)},
	"hamakaze": {"roof": Color(0.22, 0.28, 0.4), "ridge": Color(0.62, 0.3, 0.18), "wall": Color(0.74, 0.6, 0.44), "timber": Color(0.4, 0.26, 0.15),
		"plinth": Color(0.5, 0.48, 0.42), "door": Color(0.35, 0.22, 0.12), "lattice": Color(0.28, 0.18, 0.1), "accent": Color(0.85, 0.7, 0.25)},
	"air": {"roof": Color(0.24, 0.45, 0.74), "ridge": Color(0.95, 0.64, 0.2), "wall": Color(0.93, 0.9, 0.84), "timber": Color(0.82, 0.55, 0.22),
		"plinth": Color(0.8, 0.78, 0.72), "door": Color(0.55, 0.3, 0.12), "lattice": Color(0.5, 0.35, 0.18), "accent": Color(0.95, 0.62, 0.15)},
	"water": {"roof": Color(0.82, 0.9, 0.98), "ridge": Color(0.22, 0.38, 0.72), "wall": Color(0.84, 0.91, 0.98), "timber": Color(0.25, 0.4, 0.72),
		"plinth": Color(0.7, 0.8, 0.92), "door": Color(0.18, 0.28, 0.55), "lattice": Color(0.3, 0.45, 0.75), "accent": Color(0.25, 0.42, 0.8)},
	"swamp": {"roof": Color(0.56, 0.49, 0.3), "ridge": Color(0.4, 0.33, 0.2), "wall": Color(0.48, 0.38, 0.24), "timber": Color(0.34, 0.25, 0.15),
		"plinth": Color(0.3, 0.27, 0.2), "door": Color(0.22, 0.16, 0.1), "lattice": Color(0.25, 0.18, 0.1), "accent": Color(0.5, 0.6, 0.3)},
}

static func style(culture: String) -> Dictionary:
	match culture:
		"north", "south": return STYLES.water
		"sand": return STYLES.earth
	return STYLES.get(culture, STYLES.earth)

# ---------------------------------------------------------------------------
# Mesh builder: flat-shaded solids and smooth-shaded curved surfaces
# ---------------------------------------------------------------------------
class Builder:
	var flat := SurfaceTool.new()
	var smooth := SurfaceTool.new()
	var n_flat := 0
	var n_smooth := 0

	func _init() -> void:
		flat.begin(Mesh.PRIMITIVE_TRIANGLES)
		smooth.begin(Mesh.PRIMITIVE_TRIANGLES)

	## Triangle facing `nd` (Godot treats clockwise as the front face).
	func tri(a: Vector3, b: Vector3, c: Vector3, col: Color, nd: Vector3, is_smooth: bool = false) -> void:
		var cr := (b - a).cross(c - a)
		if cr.length_squared() < 1e-12:
			return
		if cr.dot(nd) > 0.0:
			var t := b
			b = c
			c = t
			cr = -cr
		var n := -cr.normalized()
		if is_smooth:
			for v in [a, b, c]:
				smooth.set_color(col)
				smooth.add_vertex(v)
			n_smooth += 3
		else:
			for v in [a, b, c]:
				flat.set_color(col)
				flat.set_normal(n)
				flat.add_vertex(v)
			n_flat += 3

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, nd: Vector3, is_smooth: bool = false) -> void:
		tri(a, b, c, col, nd, is_smooth)
		tri(a, c, d, col, nd, is_smooth)

	## Per-vertex colours on a smooth quad (for gradients and tile stripes).
	func quad_c(a: Vector3, b: Vector3, c: Vector3, d: Vector3, ca: Color, cb: Color, cc: Color, cd: Color, nd: Vector3) -> void:
		_tri_c(a, b, c, ca, cb, cc, nd)
		_tri_c(a, c, d, ca, cc, cd, nd)

	func _tri_c(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color, nd: Vector3) -> void:
		var cr := (b - a).cross(c - a)
		if cr.length_squared() < 1e-12:
			return
		if cr.dot(nd) > 0.0:
			var t := b
			b = c
			c = t
			var tc := cb
			cb = cc
			cc = tc
		smooth.set_color(ca)
		smooth.add_vertex(a)
		smooth.set_color(cb)
		smooth.add_vertex(b)
		smooth.set_color(cc)
		smooth.add_vertex(c)
		n_smooth += 3

	func box(center: Vector3, size: Vector3, col: Color, rot_y: float = 0.0) -> void:
		var h := size * 0.5
		var b := Basis(Vector3.UP, rot_y)
		var p := func(x: float, y: float, z: float) -> Vector3: return center + b * Vector3(x * h.x, y * h.y, z * h.z)
		var faces := [
			[Vector3(0, 1, 0), [[-1, 1, -1], [1, 1, -1], [1, 1, 1], [-1, 1, 1]]],
			[Vector3(0, -1, 0), [[-1, -1, -1], [1, -1, -1], [1, -1, 1], [-1, -1, 1]]],
			[Vector3(1, 0, 0), [[1, -1, -1], [1, 1, -1], [1, 1, 1], [1, -1, 1]]],
			[Vector3(-1, 0, 0), [[-1, -1, -1], [-1, 1, -1], [-1, 1, 1], [-1, -1, 1]]],
			[Vector3(0, 0, 1), [[-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1]]],
			[Vector3(0, 0, -1), [[-1, -1, -1], [1, -1, -1], [1, 1, -1], [-1, 1, -1]]],
		]
		for f in faces:
			var q: Array = f[1]
			var vs := []
			for c in q:
				vs.append(p.call(c[0], c[1], c[2]))
			var shade := 1.0 if f[0].y >= 0.0 else 0.8
			quad(vs[0], vs[1], vs[2], vs[3], col * shade, b * f[0])

	func cyl(base: Vector3, r_bot: float, r_top: float, h: float, col: Color, segs: int = 10, cap: bool = true) -> void:
		for i in segs:
			var a0 := TAU * i / segs
			var a1 := TAU * (i + 1) / segs
			var d0 := Vector3(cos(a0), 0, sin(a0))
			var d1 := Vector3(cos(a1), 0, sin(a1))
			var nd := (d0 + d1).normalized()
			quad(base + d0 * r_bot, base + d1 * r_bot, base + d1 * r_top + Vector3(0, h, 0), base + d0 * r_top + Vector3(0, h, 0), col, nd, true)
			if cap and r_top > 0.001:
				tri(base + Vector3(0, h, 0), base + d0 * r_top + Vector3(0, h, 0), base + d1 * r_top + Vector3(0, h, 0), col, Vector3.UP)

	## Revolved profile [(radius, height)], banded colours per ring.
	func lathe(center: Vector3, profile: Array, cols: Array, segs: int = 20, outward: bool = true) -> void:
		for i in profile.size() - 1:
			var p0: Vector2 = profile[i]
			var p1: Vector2 = profile[i + 1]
			var c0: Color = cols[i % cols.size()]
			var c1: Color = cols[(i + 1) % cols.size()]
			for s in segs:
				var a0 := TAU * s / segs
				var a1 := TAU * (s + 1) / segs
				var d0 := Vector3(cos(a0), 0, sin(a0))
				var d1 := Vector3(cos(a1), 0, sin(a1))
				var mid := (d0 + d1).normalized() * (p0.x + p1.x) * 0.5 + Vector3(0, (p0.y + p1.y) * 0.5, 0)
				var nd := mid.normalized() if outward else -mid.normalized()
				quad_c(center + d0 * p0.x + Vector3(0, p0.y, 0), center + d1 * p0.x + Vector3(0, p0.y, 0),
					center + d1 * p1.x + Vector3(0, p1.y, 0), center + d0 * p1.x + Vector3(0, p1.y, 0), c0, c0, c1, c1, nd)

	func commit() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		if n_flat > 0:
			flat.commit(mesh)
		if n_smooth > 0:
			smooth.index()
			smooth.generate_normals()
			smooth.commit(mesh)
		return mesh

# ---------------------------------------------------------------------------
# Roofs
# ---------------------------------------------------------------------------
## Hip roof with a concave sweep and upturned corners, as a closed slab so it
## takes an ink outline. `base` is the eave-level centre; the ridge runs
## along X. `curl` lifts the corners (Fire Nation roofs curl most).
static func roof(b: Builder, base: Vector3, w: float, d: float, h: float, over: float, curl: float, st: Dictionary, rot_y: float = 0.0, thick: float = 0.14) -> void:
	var rx: float = maxf(0.0, (w - d) * 0.5)
	var rings := 7
	var per_side := 8
	var basis := Basis(Vector3.UP, rot_y)
	var top := []
	var under := []
	var col_top := []
	for i in rings + 1:
		var t := float(i) / rings
		var ex: float = lerpf(w * 0.5 + over, rx, t)
		var ez: float = lerpf(d * 0.5 + over, 0.0, t)
		var y := h * pow(t, 1.7)
		var ring := []
		var ring_u := []
		var cols := []
		var pts := _rect_ring(ex, ez, per_side)
		for k in pts.size():
			var pt: Vector3 = pts[k][0]
			var cf: float = pts[k][1]
			var lift := curl * pow(cf, 3.0) * pow(1.0 - t, 2.0)
			var flare := Vector3(pt.x, 0, pt.z).normalized() * curl * 0.35 * pow(cf, 3.0) * pow(1.0 - t, 2.0)
			var v := Vector3(pt.x, y + lift, pt.z) + flare
			ring.append(base + basis * v)
			ring_u.append(base + basis * (v - Vector3(0, thick * (1.0 - t * 0.6), 0)))
			# tile channels: alternate light and dark rows running down the slope
			var stripe := 1.0 if k % 2 == 0 else 0.84
			cols.append(st.roof * stripe * (1.0 - 0.12 * t))
		top.append(ring)
		under.append(ring_u)
		col_top.append(cols)
	var n: int = top[0].size()
	for i in rings:
		for k in n:
			var k2 := (k + 1) % n
			var a: Vector3 = top[i][k]
			var bb: Vector3 = top[i][k2]
			var c: Vector3 = top[i + 1][k2]
			var dd: Vector3 = top[i + 1][k]
			var outward := ((a + bb) * 0.5 - base)
			outward.y = 0.0
			var nd := (Vector3.UP * 1.2 + outward.normalized()).normalized()
			b.quad_c(a, bb, c, dd, col_top[i][k], col_top[i][k2], col_top[i + 1][k2], col_top[i + 1][k], nd)
			var ua: Vector3 = under[i][k]
			var ub: Vector3 = under[i][k2]
			var uc: Vector3 = under[i + 1][k2]
			var ud: Vector3 = under[i + 1][k]
			var soffit: Color = st.timber * 0.7
			b.quad(ua, ub, uc, ud, soffit, -nd, true)
	# eave fascia: the painted edge of the roof
	for k in n:
		var k2 := (k + 1) % n
		var a: Vector3 = top[0][k]
		var bb: Vector3 = top[0][k2]
		var outward := ((a + bb) * 0.5 - base)
		outward.y = 0.0
		b.quad(a, bb, under[0][k2], under[0][k], st.ridge, outward.normalized())
	# ridge beam with upturned ends
	var ry := base.y + h
	if rx > 0.05:
		b.box(base + basis * Vector3(0, h + 0.06, 0), Vector3(rx * 2.0 + 0.3, 0.2, 0.22), st.ridge, rot_y)
		for sgn in [-1.0, 1.0]:
			var e := base + basis * Vector3(sgn * (rx + 0.15), h + 0.2, 0)
			b.box(e, Vector3(0.18, 0.42, 0.2), st.ridge, rot_y + sgn * 0.35)
	else:
		b.cyl(Vector3(base.x, ry, base.z), 0.12, 0.0, 0.7, st.ridge, 8)

## Points around a rectangle with a "corner factor" (1 at corners, 0 mid-side).
static func _rect_ring(ex: float, ez: float, per_side: int) -> Array:
	var out := []
	var corners := [Vector3(-ex, 0, -ez), Vector3(ex, 0, -ez), Vector3(ex, 0, ez), Vector3(-ex, 0, ez)]
	for s in 4:
		var c0: Vector3 = corners[s]
		var c1: Vector3 = corners[(s + 1) % 4]
		for j in per_side:
			var f := float(j) / per_side
			var cf := pow(absf(f - 0.5) * 2.0, 2.0)
			out.append([c0.lerp(c1, f), cf])
	return out

# ---------------------------------------------------------------------------
# Buildings
# ---------------------------------------------------------------------------
## A timber-and-plaster hall on a stone plinth. Returns the mesh node.
## `floors` stacks storeys, each with its own skirt roof (pagoda-like).
static func hall(culture: String, w: float, d: float, floors: int = 1, rot_y: float = 0.0, opts: Dictionary = {}) -> Node3D:
	var st := style(culture)
	var b := Builder.new()
	var basis := Basis(Vector3.UP, rot_y)
	var plinth_h: float = opts.get("plinth", 0.45)
	var floor_h: float = opts.get("floor_h", 2.8)
	var curl: float = opts.get("curl", 0.55 if culture == "fire" else 0.35)
	var p := func(v: Vector3) -> Vector3: return basis * v
	# plinth with a front step
	b.box(p.call(Vector3(0, plinth_h * 0.5, 0)), Vector3(w + 0.8, plinth_h, d + 0.8), st.plinth, rot_y)
	b.box(p.call(Vector3(0, plinth_h * 0.25, d * 0.5 + 0.7)), Vector3(1.8, plinth_h * 0.5, 0.6), st.plinth * 0.92, rot_y)
	var y := plinth_h
	var cw := w
	var cd := d
	for f in floors:
		_storey(b, st, cw, cd, y, floor_h, basis, f == 0, culture)
		y += floor_h
		var last := f == floors - 1
		var over: float = 0.9 if last else 0.75
		var rh: float = (cd * 0.42 + 0.6) if last else 0.9
		if not last:
			# skirt roof around the upper storey
			roof(b, p.call(Vector3(0, y, 0)), cw, cd, rh, over, curl, st, rot_y, 0.12)
			cw *= 0.78
			cd *= 0.78
			y += 0.35
		else:
			roof(b, p.call(Vector3(0, y, 0)), cw, cd, rh, over, curl, st, rot_y)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = material()
	var root := Node3D.new()
	root.add_child(mi)
	return root

static func _storey(b: Builder, st: Dictionary, w: float, d: float, y: float, h: float, basis: Basis, ground: bool, culture: String) -> void:
	var p := func(v: Vector3) -> Vector3: return basis * v
	var rot_y := basis.get_euler().y
	# walls
	b.box(p.call(Vector3(0, y + h * 0.5, 0)), Vector3(w, h, d), st.wall, rot_y)
	# base course and lintel beam
	b.box(p.call(Vector3(0, y + 0.15, 0)), Vector3(w + 0.06, 0.3, d + 0.06), st.timber * 0.8, rot_y)
	b.box(p.call(Vector3(0, y + h - 0.2, 0)), Vector3(w + 0.08, 0.3, d + 0.08), st.timber, rot_y)
	# columns along the front and back, at the corners of the sides
	var cols := maxi(2, int(w / 2.2) + 1)
	for i in cols:
		var x := lerpf(-w * 0.5, w * 0.5, float(i) / (cols - 1))
		for z in [d * 0.5 + 0.05, -d * 0.5 - 0.05]:
			b.cyl(p.call(Vector3(x, y, z)), 0.16, 0.15, h, st.timber, 8, false)
	for z in [-d * 0.5, d * 0.5]:
		for x in [-w * 0.5 - 0.05, w * 0.5 + 0.05]:
			b.cyl(p.call(Vector3(x, y, z)), 0.16, 0.15, h, st.timber, 8, false)
	# lattice windows between columns on the long sides; a door in the front
	for i in cols - 1:
		var x0 := lerpf(-w * 0.5, w * 0.5, float(i) / (cols - 1))
		var x1 := lerpf(-w * 0.5, w * 0.5, float(i + 1) / (cols - 1))
		var cx := (x0 + x1) * 0.5
		var span := (x1 - x0) * 0.62
		var is_door := ground and i == int((cols - 1) / 2)
		for side in [1.0, -1.0]:
			var z: float = side * (d * 0.5 + 0.03)
			if is_door and side > 0.0:
				b.box(p.call(Vector3(cx, y + h * 0.4, z)), Vector3(span, h * 0.72, 0.06), st.door, rot_y)
				b.box(p.call(Vector3(cx, y + h * 0.78, z + 0.02)), Vector3(span + 0.2, 0.12, 0.08), st.accent, rot_y)
			else:
				var wy := y + h * 0.55
				b.box(p.call(Vector3(cx, wy, z)), Vector3(span, h * 0.36, 0.05), st.lattice, rot_y)
				for k in 3:
					var bx := cx + (k - 1) * span / 3.0
					b.box(p.call(Vector3(bx, wy, z + side * 0.02)), Vector3(0.05, h * 0.36, 0.05), st.wall * 0.85, rot_y)
				b.box(p.call(Vector3(cx, wy, z + side * 0.02)), Vector3(span, 0.05, 0.05), st.wall * 0.85, rot_y)

## Water Tribe ice dome, built in courses of ice blocks, with an entrance.
static func ice_dome(r: float, rot_y: float = 0.0) -> Node3D:
	var st := STYLES.water
	var b := Builder.new()
	var prof := []
	var cols := []
	var rows := 9
	for i in rows + 1:
		var a := PI * 0.5 * float(i) / rows
		prof.append(Vector2(r * cos(a), r * sin(a) * 0.95))
		cols.append(st.wall if i % 2 == 0 else st.wall * Color(0.9, 0.94, 1.0))
	b.lathe(Vector3.ZERO, prof, cols, 22)
	# entrance tunnel
	var basis := Basis(Vector3.UP, rot_y)
	for i in 6:
		var a0 := PI * i / 6.0
		var a1 := PI * (i + 1) / 6.0
		var z0 := r * 0.75
		var z1 := r * 1.25
		var rr := r * 0.38
		var v0 := Vector3(cos(a0) * rr, sin(a0) * rr, 0)
		var v1 := Vector3(cos(a1) * rr, sin(a1) * rr, 0)
		var nd := basis * ((v0 + v1).normalized())
		b.quad(basis * (v0 + Vector3(0, 0, z0)), basis * (v1 + Vector3(0, 0, z0)), basis * (v1 + Vector3(0, 0, z1)), basis * (v0 + Vector3(0, 0, z1)), st.wall * 0.95, nd, true)
	b.box(basis * Vector3(0, r * 0.18, r * 1.24), Vector3(r * 0.5, r * 0.36, 0.05), st.door, rot_y)
	# a blue banner pole
	b.cyl(Vector3(r * 0.6, 0, -r * 0.4), 0.05, 0.05, r * 1.6, st.timber, 6)
	b.box(Vector3(r * 0.6 + 0.35, r * 1.35, -r * 0.4), Vector3(0.6, 0.4, 0.04), st.accent)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = material()
	var root := Node3D.new()
	root.add_child(mi)
	return root

## Air Nomad tower: white stone drum, balcony, and a tall blue cone roof.
static func air_tower(r: float, h: float) -> Node3D:
	var st := STYLES.air
	var b := Builder.new()
	b.cyl(Vector3.ZERO, r * 1.15, r * 1.1, 0.6, st.plinth, 16)
	b.cyl(Vector3(0, 0.6, 0), r, r * 0.92, h, st.wall, 16)
	b.cyl(Vector3(0, 0.6 + h * 0.55, 0), r * 1.12, r * 1.12, 0.25, st.timber, 16)
	b.cyl(Vector3(0, 0.6 + h - 0.3, 0), r * 1.05, r * 1.05, 0.3, st.ridge, 16)
	# swept cone roof as a lathe with an upturned rim
	var y0 := 0.6 + h
	var prof := [Vector2(r * 1.45, y0 + 0.25), Vector2(r * 1.3, y0 + 0.15), Vector2(r * 1.05, y0 + 0.35), Vector2(r * 0.7, y0 + r * 0.9), Vector2(r * 0.35, y0 + r * 1.7), Vector2(0.02, y0 + r * 2.4)]
	b.lathe(Vector3.ZERO, prof, [st.roof * 0.85, st.roof, st.roof, st.roof * 1.05, st.roof * 1.1, st.roof], 18)
	b.cyl(Vector3(0, y0 + r * 2.35, 0), 0.08, 0.0, 0.9, st.ridge, 6)
	# arched windows
	for i in 6:
		var a := TAU * i / 6.0
		var dv := Vector3(cos(a), 0, sin(a))
		b.box(dv * (r * 0.97) + Vector3(0, 0.6 + h * 0.75, 0), Vector3(0.5, 1.0, 0.08), st.lattice, -a + PI * 0.5)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = material()
	var root := Node3D.new()
	root.add_child(mi)
	return root

## Stilt hut with a thatched hip roof (Foggy Swamp, river villages).
static func stilt_hut(w: float, d: float, rot_y: float = 0.0) -> Node3D:
	var st := STYLES.swamp
	var b := Builder.new()
	var basis := Basis(Vector3.UP, rot_y)
	for x in [-w * 0.45, w * 0.45]:
		for z in [-d * 0.45, d * 0.45]:
			b.cyl(basis * Vector3(x, 0, z), 0.12, 0.1, 1.3, st.timber, 6)
	b.box(basis * Vector3(0, 1.35, 0), Vector3(w + 0.4, 0.15, d + 0.4), st.timber, rot_y)
	b.box(basis * Vector3(0, 2.3, 0), Vector3(w, 1.9, d), st.wall, rot_y)
	b.box(basis * Vector3(0, 2.0, d * 0.5 + 0.02), Vector3(0.8, 1.3, 0.05), st.door, rot_y)
	roof(b, basis * Vector3(0, 3.25, 0), w, d, d * 0.5 + 0.4, 0.6, 0.1, st, rot_y, 0.2)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = material()
	var root := Node3D.new()
	root.add_child(mi)
	return root

## A stretch of city wall with walkway and crenellations, along X.
static func wall(culture: String, length: float, h: float, rot_y: float = 0.0) -> Node3D:
	var st := style(culture)
	var ice := culture in ["north", "south"]
	var b := Builder.new()
	var stone: Color = st.wall if ice else st.plinth
	b.box(Vector3(0, h * 0.5, 0), Vector3(length, h, 1.6), stone, rot_y)
	b.box(Vector3(0, h + 0.05, 0), Vector3(length + 0.1, 0.1, 1.8), stone * 0.9, rot_y)
	var basis := Basis(Vector3.UP, rot_y)
	var n := int(length / 1.6)
	for i in n:
		var x := -length * 0.5 + (i + 0.5) * length / n
		if i % 2 == 0:
			b.box(basis * Vector3(x, h + 0.45, 0.7), Vector3(length / n * 0.9, 0.8, 0.3), stone, rot_y)
	if not ice:
		# a band of painted tile coping, as on Ba Sing Se's walls
		b.box(Vector3(0, h - 0.25, 0), Vector3(length + 0.04, 0.2, 1.66), st.roof, rot_y)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = material()
	var root := Node3D.new()
	root.add_child(mi)
	return root

## City gate: two towers and a roofed gatehouse over a passage along Z.
static func gate(culture: String, h: float) -> Node3D:
	var st := style(culture)
	var ice := culture in ["north", "south"]
	var b := Builder.new()
	var stone: Color = st.wall if ice else st.plinth
	for x in [-3.6, 3.6]:
		b.box(Vector3(x, h * 0.6, 0), Vector3(3.0, h * 1.2, 3.0), stone)
	b.box(Vector3(0, h * 1.05, 0), Vector3(4.4, h * 0.5, 2.6), stone)
	if ice:
		b.box(Vector3(0, h * 1.35, 0), Vector3(10.4, 0.3, 3.2), st.accent)
	else:
		b.box(Vector3(0, h * 1.3 + 0.6, 0), Vector3(9.0, 1.2, 2.4), st.wall)
		b.box(Vector3(0, h * 1.3 + 0.6, 1.22), Vector3(1.4, 0.7, 0.04), st.accent)
		roof(b, Vector3(0, h * 1.3 + 1.2, 0), 9.4, 3.4, 1.5, 0.9, 0.5 if culture == "fire" else 0.32, st)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = material()
	var root := Node3D.new()
	root.add_child(mi)
	return root

## Rice paddy or field patch: flat water with rows of shoots.
static func paddy(w: float, d: float, water: bool) -> Node3D:
	var b := Builder.new()
	var bank := Color(0.42, 0.34, 0.2)
	b.box(Vector3(0, 0.08, 0), Vector3(w + 0.6, 0.16, d + 0.6), bank)
	var fill := Color(0.42, 0.62, 0.62) if water else Color(0.48, 0.36, 0.2)
	b.box(Vector3(0, 0.12, 0), Vector3(w, 0.1, d), fill)
	var shoot := Color(0.45, 0.7, 0.25) if water else Color(0.55, 0.62, 0.22)
	var rows := int(d / 0.7)
	for r in rows:
		var z := -d * 0.5 + (r + 0.5) * d / rows
		var nshoots := int(w / 0.6)
		for k in nshoots:
			var x := -w * 0.5 + (k + 0.5) * w / nshoots
			b.box(Vector3(x, 0.32, z), Vector3(0.12, 0.35, 0.12), shoot)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = material(false)
	var root := Node3D.new()
	root.add_child(mi)
	return root

## Paper lantern on a post (hangs from eaves when `post` is false).
static func lantern(color: Color, post: bool = true) -> Node3D:
	var b := Builder.new()
	var y := 2.3 if post else 0.0
	if post:
		b.cyl(Vector3.ZERO, 0.06, 0.05, 2.5, Color(0.3, 0.2, 0.12), 6)
		b.box(Vector3(0.25, 2.45, 0), Vector3(0.6, 0.06, 0.06), Color(0.3, 0.2, 0.12))
	var prof := [Vector2(0.05, y - 0.26), Vector2(0.13, y - 0.2), Vector2(0.16, y - 0.07), Vector2(0.13, y + 0.06), Vector2(0.05, y + 0.11)]
	b.lathe(Vector3(0.45 if post else 0.0, 0, 0), prof, [color * 0.8, color, color, color * 0.9, color * 0.7], 10)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = material(true, 0.35)
	var root := Node3D.new()
	root.add_child(mi)
	return root
