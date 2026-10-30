extends RefCounted
## Battlefield set dressing: CC0 nature-kit vegetation and rocks repainted in
## the cel style, painted mountain backdrops, and earthbending stone with
## visible strata instead of plain boxes and spheres.

const Arch = preload("res://scripts/town/arch.gd")
const CB = preload("res://scripts/actors/character_builder.gd")

static var _scenes := {}

## A nature-kit model with toon materials, optionally tinted (snow, sand, ash).
static func nature(name: String, tint: Color = Color.WHITE) -> Node3D:
	var ps: PackedScene = _scenes.get(name)
	if ps == null:
		ps = load("res://assets/nature/%s.gltf" % name)
		_scenes[name] = ps
	var n: Node3D = ps.instantiate()
	_toon(n, tint)
	return n

static func _toon(n: Node, tint: Color) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		for s in mi.mesh.get_surface_count():
			mi.set_surface_override_material(s, CB.toon_from(mi.mesh.surface_get_material(s), {"tint": tint, "saturation": 1.1}))
	for c in n.get_children():
		_toon(c, tint)

## Vegetation and rocks per biome: [trees, small plants, rocks, rock tint].
static func palette(biome: String) -> Dictionary:
	match biome:
		"forest": return {"trees": ["CommonTree_1", "CommonTree_2", "CommonTree_3", "Pine_1", "Pine_3"], "small": ["Bush_Common", "Fern_1", "Grass_Common_Tall"], "rocks": Color(0.95, 0.95, 0.95)}
		"swamp": return {"trees": ["TwistedTree_1", "TwistedTree_2", "TwistedTree_4", "DeadTree_2"], "small": ["Fern_1", "Plant_7_Big", "Mushroom_Common"], "rocks": Color(0.8, 0.85, 0.7)}
		"snow": return {"trees": ["Pine_2", "Pine_4"], "small": [], "rocks": Color(1.25, 1.3, 1.4), "tree_tint": Color(0.85, 0.95, 1.05)}
		"desert", "beach": return {"trees": ["DeadTree_1", "DeadTree_3"], "small": ["Grass_Wispy_Short"], "rocks": Color(1.3, 1.1, 0.8)}
		"volcanic": return {"trees": ["DeadTree_4", "DeadTree_5", "TwistedTree_3"], "small": [], "rocks": Color(0.55, 0.5, 0.5)}
		"highland", "mountain": return {"trees": ["Pine_1", "Pine_5", "CommonTree_4"], "small": ["Grass_Wispy_Tall", "Flower_4_Group"], "rocks": Color(1.0, 1.0, 1.0)}
	return {"trees": ["CommonTree_1", "CommonTree_5", "Pine_2"], "small": ["Grass_Common_Tall", "Flower_3_Group", "Bush_Common_Flowers", "Clover_2"], "rocks": Color(1.0, 1.0, 1.0)}

static func rock(scale: float, tint: Color) -> Node3D:
	var n := nature(["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"][randi() % 3], tint)
	n.scale = Vector3.ONE * scale
	n.rotation.y = randf() * TAU
	return n

## Painted mountains on the horizon: craggy lathed peaks with snow on top.
static func mountains(base: Color, snowy: bool, seed: int) -> MeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var b = Arch.Builder.new()
	for i in 20:
		var a := TAU * i / 20.0 + rng.randf_range(-0.1, 0.1)
		var r := rng.randf_range(170.0, 260.0)
		var h := rng.randf_range(35.0, 85.0)
		var w := rng.randf_range(40.0, 70.0)
		var c := Vector3(cos(a) * r, -4.0, sin(a) * r)
		var prof := []
		var cols := []
		var steps := 6
		for k in steps + 1:
			var t := float(k) / steps
			prof.append(Vector2(w * (1.0 - t) * rng.randf_range(0.85, 1.1) + 1.0, h * t))
			var col: Color = base.darkened(0.15 + 0.1 * (k % 2))
			if (snowy or h > 70.0) and t > 0.6:
				col = Color(0.92, 0.94, 0.98)
			cols.append(col)
		b.lathe(c, prof, cols, 7)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	var m: ShaderMaterial = Arch.material(false).duplicate()
	m.set_shader_parameter("brush_scale", 0.04)
	m.set_shader_parameter("brush_strength", 0.16)
	mi.material_override = m
	return mi

## An earthbent wall: stacked slabs with uneven strata and a broken top edge.
static func earth_wall(width: float, height: float, col: Color) -> Node3D:
	var b = Arch.Builder.new()
	var layers := maxi(3, int(height / 0.45))
	var lh := height / layers
	for i in layers:
		var y := -height * 0.5 + (i + 0.5) * lh
		var shade := 0.85 + 0.12 * ((i * 7) % 3) / 2.0
		var inset := randf_range(-0.06, 0.06)
		b.box(Vector3(randf_range(-0.08, 0.08), y, inset), Vector3(width + randf_range(-0.15, 0.1), lh * 0.98, 0.8 + randf_range(-0.08, 0.1)), col * shade)
	# jagged crest
	var n := int(width / 0.5)
	for k in n:
		var x := -width * 0.5 + (k + 0.5) * width / n
		var hh := randf_range(0.1, 0.45)
		b.box(Vector3(x, height * 0.5 + hh * 0.5, randf_range(-0.1, 0.1)), Vector3(width / n * 0.95, hh, 0.7), col * 0.95)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = Arch.material(true)
	var root := Node3D.new()
	root.add_child(mi)
	return root
