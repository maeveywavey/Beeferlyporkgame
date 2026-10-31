extends RefCounted
## A working mine: a rock hillside with a timber-framed adit, an ore wagon,
## barrels, crates, tools and lamps, from the owner's CC0 mine kit (elbolilloduro).
## The kit's own rock and timber textures are replaced by several different
## foxtex stones and woods, noise-blended (landscape.gd), as the owner asked.
## Modern pieces (generator, detonator, TNT, petrol can, cables, lockers) are not used.

const Land = preload("res://scripts/battle/landscape.gd")
const Arch = preload("res://scripts/town/arch.gd")
const KIT := "res://assets/thirdparty/elbolilloduro_mine/Minas/Models/Mines.fbx"

## Builds the site with its entrance at `c`, facing +Z (south), into layout L.
static func build(L, c: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("mine")
	var kit: Node = load(KIT).instantiate()
	var rock_mats := [Land.rock_material("mountain"), Land.rock_material("grass"), Land.rock_material("desert")]
	var wood := Land.wood_material()
	# the hillside, with the adit cut into its south face
	for k in 3:
		var hill: MeshInstance3D = Land.cliff("mountain", 6.5 - k * 1.2, 7.0 - k * 1.2, rng)
		hill.material_override = rock_mats[k % 3]
		L.add(hill, c + Vector3((k - 1) * 5.5, 0, -5.5 - k * 0.6))
	# the timber frame of the entrance and a dark opening
	var b = Arch.Builder.new()
	b.box(c + Vector3(-1.5, 1.35, 0), Vector3(0.38, 2.7, 0.38), Color.WHITE)
	b.box(c + Vector3(1.5, 1.35, 0), Vector3(0.38, 2.7, 0.38), Color.WHITE)
	b.box(c + Vector3(0, 2.8, 0), Vector3(3.8, 0.4, 0.44), Color.WHITE)
	b.box(c + Vector3(0, 2.5, 0.05), Vector3(2.6, 0.18, 0.2), Color.WHITE)
	var frame := MeshInstance3D.new()
	frame.mesh = b.commit()
	frame.material_override = wood
	L.root.add_child(frame)
	var hole := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.7, 2.6, 0.1)
	hole.mesh = bm
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.02, 0.02, 0.025)
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hole.material_override = dark
	L.root.add_child(hole)
	hole.position = c + Vector3(0, 1.3, -0.25)
	# kit pieces: [name, offset from the entrance (x, z), yaw degrees, material kind]
	var layout := [
		["Wagon", Vector3(3.6, 0, 3.2), 25.0, ""],
		["Barrel", Vector3(-3.6, 0, 1.6), 0.0, ""],
		["Barrel_01", Vector3(-4.5, 0, 2.6), 40.0, ""],
		["Barrel_02", Vector3(-3.4, 0, 3.0), 10.0, ""],
		["Box_Wood_03", Vector3(-2.2, 0, 3.8), 15.0, "wood"],
		["Box_Wood_03", Vector3(-3.4, 0, 4.6), -20.0, "wood"],
				["Tray", Vector3(2.2, 0, 1.4), 0.0, ""],
		["Shovel", Vector3(-2.4, 0.12, 1.2), 30.0, ""],
		["Beak", Vector3(-5.0, 0, 3.8), 0.0, ""],
		["Lamp", Vector3(2.0, 0, 0.6), 0.0, ""],
		["Gravel", Vector3(5.0, 0, 5.4), 90.0, "rock"],
		["Gravel_01", Vector3(-5.8, 0, 6.0), 0.0, "rock"],
		["Rock_11", Vector3(8.5, 0, -2.5), 0.0, "rock"],
		["Rock_12", Vector3(-8.5, 0, -3.0), 0.0, "rock"],
		["Rock_05", Vector3(6.5, 0, 6.5), 30.0, "rock"],
		["Rock", Vector3(-7.0, 0, 5.0), 0.0, "rock"],
		["Rock_01", Vector3(9.0, 0, 3.5), 0.0, "rock"],
	]
	var ri := 0
	for e in layout:
		var src: Node3D = kit.get_node_or_null(e[0])
		if src == null:
			continue
		var node: Node3D = src.duplicate()
		var kit_y: float = src.position.y
		L.root.add_child(node)
		node.position = c + Vector3(e[1].x, kit_y + e[1].y, e[1].z)
		node.rotate_y(deg_to_rad(e[2]))
		match e[3]:
			"rock":
				_retexture(node, rock_mats[ri % 3])
				ri += 1
			"wood":
				_retexture(node, wood)
		L.circle(c + e[1], 1.0)
	kit.free()
	# lanterns on posts either side of the entrance
	for sg in [-1.0, 1.0]:
		L.street_lantern(c + Vector3(sg * 2.6, 0, 1.2), 0.0)
	# the area is not walkable through the hill; miners work the yard
	L.block(c + Vector3(0, 0, -4.5), 16.0, 8.0)
	for i in 2:
		L.npc_spot(c + Vector3(-1.0 + i * 2.0, 0, 2.2), PI, "", "ual2/Farm_Harvest", {"look": "soldier"})

static func _retexture(n: Node, mat: Material) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = mat
	for ch in n.get_children():
		_retexture(ch, mat)
