extends RefCounted
## Builds low-poly soldier and mount models from primitives. The returned
## dictionary holds the pivot nodes the unit animates.

const MB = preload("res://scripts/world/map_builder.gd")

static func _part(mesh: Mesh, color: Color, pos: Vector3, parent: Node3D, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = MB.mat(color, 0.85)
	m.position = pos
	m.rotation_degrees = rot
	parent.add_child(m)
	return m

static func _box(size: Vector3, color: Color, pos: Vector3, parent: Node3D, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _part(b, color, pos, parent, rot)

static func _cyl(rt: float, rb: float, h: float, color: Color, pos: Vector3, parent: Node3D, rot: Vector3 = Vector3.ZERO, segs: int = 8) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return _part(c, color, pos, parent, rot)

static func _sph(r: float, color: Color, pos: Vector3, parent: Node3D, hemi: bool = false) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * (1.0 if hemi else 2.0)
	s.is_hemisphere = hemi
	s.radial_segments = 12
	s.rings = 6
	return _part(s, color, pos, parent)

## Only the mount (used under the rigged riders). Returns {mount, legs, seat}.
static func build_mount_only(mount: String) -> Dictionary:
	var root := Node3D.new()
	var tmp := build({}, "fists", "", false, mount, Color.WHITE, Color.BLACK)
	var m: Node3D = tmp.mount
	m.get_parent().remove_child(m)
	tmp.root.free()
	for leg in tmp.mount_legs:
		pass
	return {"mount": m, "legs": tmp.mount_legs, "seat": tmp.seat}

## look: {body, trim, helmet}, weapon: item id, ranged: item id, shield: bool,
## mount: item id, skin/hair colors.
static func build(look: Dictionary, weapon: String, ranged: String, shield: bool, mount: String, skin: Color, hair: Color) -> Dictionary:
	var root := Node3D.new()
	var rider := Node3D.new()
	root.add_child(rider)
	var parts := {"root": root, "rider": rider}
	var body_c: Color = look.get("body", Color.GRAY)
	var trim_c: Color = look.get("trim", Color.DIM_GRAY)
	var seat := 0.0
	if mount != "":
		var mount_node := Node3D.new()
		root.add_child(mount_node)
		parts.mount = mount_node
		parts.mount_legs = []
		if Data.item(mount).get("look", "") == "rhino":
			seat = 1.15
			var body := _sph(1.0, Color(0.42, 0.38, 0.32), Vector3(0, 1.25, 0), mount_node)
			body.scale = Vector3(0.95, 0.75, 1.6)
			_sph(0.5, Color(0.42, 0.38, 0.32), Vector3(0, 1.3, 1.65), mount_node)
			_cyl(0.0, 0.15, 0.6, Color(0.85, 0.8, 0.65), Vector3(0, 1.55, 2.05), mount_node, Vector3(60, 0, 0))
			_box(Vector3(1.1, 0.15, 1.0), Color(0.55, 0.12, 0.1), Vector3(0, 1.95, -0.1), mount_node)
			for i in 4:
				var leg := Node3D.new()
				leg.position = Vector3(0.55 if i % 2 == 0 else -0.55, 0.9, 0.9 if i < 2 else -0.9)
				mount_node.add_child(leg)
				_box(Vector3(0.3, 0.9, 0.3), Color(0.38, 0.34, 0.28), Vector3(0, -0.45, 0), leg)
				parts.mount_legs.append(leg)
		else:
			seat = 0.98
			var body2 := _sph(0.6, Color(0.75, 0.6, 0.35), Vector3(0, 1.35, 0), mount_node)
			body2.scale = Vector3(0.8, 0.8, 1.3)
			_cyl(0.12, 0.16, 1.0, Color(0.75, 0.6, 0.35), Vector3(0, 1.95, 0.75), mount_node, Vector3(30, 0, 0))
			_sph(0.22, Color(0.7, 0.55, 0.3), Vector3(0, 2.45, 1.0), mount_node)
			_cyl(0.0, 0.08, 0.25, Color(0.9, 0.7, 0.2), Vector3(0, 2.42, 1.25), mount_node, Vector3(90, 0, 0))
			_box(Vector3(0.6, 0.6, 0.15), Color(0.3, 0.25, 0.2), Vector3(0, 1.5, -0.8), mount_node, Vector3(-30, 0, 0))
			for i in 2:
				var leg2 := Node3D.new()
				leg2.position = Vector3(0.25 if i == 0 else -0.25, 1.0, 0.0)
				mount_node.add_child(leg2)
				_cyl(0.06, 0.08, 1.0, Color(0.85, 0.7, 0.3), Vector3(0, -0.5, 0), leg2)
				parts.mount_legs.append(leg2)
	rider.position.y = seat
	parts.seat = seat
	# Blob shadow
	var blob := CylinderMesh.new()
	blob.top_radius = 0.42 if mount == "" else 1.1
	blob.bottom_radius = blob.top_radius
	blob.height = 0.01
	blob.radial_segments = 12
	blob.rings = 1
	var bm := MeshInstance3D.new()
	bm.mesh = blob
	bm.material_override = MB.mat(Color(0, 0, 0, 0.35), 1.0, true)
	bm.position.y = 0.03
	if mount != "":
		bm.scale = Vector3(0.8, 1, 1.4)
	root.add_child(bm)
	# Legs
	var legs := []
	for side in [-1, 1]:
		var hip := Node3D.new()
		hip.position = Vector3(0.13 * side, 0.85, 0)
		rider.add_child(hip)
		_box(Vector3(0.2, 0.82, 0.22), trim_c.darkened(0.2), Vector3(0, -0.42, 0), hip)
		_box(Vector3(0.22, 0.12, 0.3), Color(0.15, 0.1, 0.08), Vector3(0, -0.82, 0.04), hip)
		if mount != "":
			hip.rotation_degrees = Vector3(-70, 0, 20 * side)
		legs.append(hip)
	parts.legs = legs
	# Torso
	var torso := Node3D.new()
	torso.position.y = 0.85
	rider.add_child(torso)
	parts.torso = torso
	_box(Vector3(0.52, 0.66, 0.3), body_c, Vector3(0, 0.33, 0), torso)
	_box(Vector3(0.55, 0.1, 0.33), trim_c, Vector3(0, 0.05, 0), torso)
	_box(Vector3(0.58, 0.14, 0.32), body_c.darkened(0.15), Vector3(0, 0.62, 0), torso)
	# skirt / robe
	_box(Vector3(0.5, 0.3, 0.3), body_c.darkened(0.1), Vector3(0, -0.12, 0), torso)
	# Head
	var head := Node3D.new()
	head.position.y = 0.92
	torso.add_child(head)
	parts.head = head
	_sph(0.17, skin, Vector3(0, 0.08, 0), head)
	_box(Vector3(0.045, 0.03, 0.02), Color(0.08, 0.06, 0.05), Vector3(0.06, 0.1, 0.158), head)
	_box(Vector3(0.045, 0.03, 0.02), Color(0.08, 0.06, 0.05), Vector3(-0.06, 0.1, 0.158), head)
	_helmet(look.get("helmet", "none"), head, hair, body_c, trim_c)
	# Arms
	var arm_r := Node3D.new()
	arm_r.position = Vector3(-0.33, 0.6, 0)
	torso.add_child(arm_r)
	_box(Vector3(0.14, 0.58, 0.14), body_c, Vector3(0, -0.26, 0), arm_r)
	_sph(0.075, skin, Vector3(0, -0.58, 0), arm_r)
	var hand_r := Node3D.new()
	hand_r.position = Vector3(0, -0.58, 0)
	arm_r.add_child(hand_r)
	parts.arm_r = arm_r
	parts.hand_r = hand_r
	var arm_l := Node3D.new()
	arm_l.position = Vector3(0.33, 0.6, 0)
	torso.add_child(arm_l)
	_box(Vector3(0.14, 0.58, 0.14), body_c, Vector3(0, -0.26, 0), arm_l)
	_sph(0.075, skin, Vector3(0, -0.58, 0), arm_l)
	parts.arm_l = arm_l
	var hand_l := Node3D.new()
	hand_l.position = Vector3(0, -0.58, 0)
	arm_l.add_child(hand_l)
	parts.hand_l = hand_l
	# Weapon in right hand (pointing forward when arm is raised)
	# Weapons extend along the arm (out of the fist) so poses read naturally.
	var wnode := Node3D.new()
	hand_r.add_child(wnode)
	wnode.rotation_degrees = Vector3(90, 0, 0)
	parts.weapon = wnode
	_weapon(Data.item(weapon).get("model", "none"), wnode, trim_c)
	if Data.item(weapon).get("model", "") in ["fans", "dual_dao", "hooks"]:
		var w2 := Node3D.new()
		hand_l.add_child(w2)
		w2.rotation_degrees = Vector3(90, 0, 0)
		_weapon(Data.item(weapon).model, w2, trim_c)
	# Ranged weapon (hidden until used)
	if ranged != "":
		var rnode := Node3D.new()
		hand_l.add_child(rnode)
		rnode.rotation_degrees = Vector3(90, 0, 0)
		rnode.visible = false
		parts.ranged = rnode
		_weapon(Data.item(ranged).get("model", "bow"), rnode, trim_c)
	if shield:
		var sh := Node3D.new()
		arm_l.add_child(sh)
		sh.position = Vector3(0.12, -0.35, 0.12)
		_cyl(0.32, 0.32, 0.06, trim_c.darkened(0.1), Vector3.ZERO, sh, Vector3(135, 0, 0), 10)
		_cyl(0.1, 0.1, 0.08, body_c, Vector3(0, -0.02, 0.02), sh, Vector3(135, 0, 0), 8)
		parts.shield = sh
	return parts

static func _helmet(style: String, head: Node3D, hair: Color, body_c: Color, trim_c: Color) -> void:
	match style:
		"fn_helmet":
			_sph(0.2, Color(0.3, 0.1, 0.08), Vector3(0, 0.12, 0), head, true)
			_box(Vector3(0.32, 0.18, 0.06), Color(0.85, 0.82, 0.75), Vector3(0, 0.05, 0.16), head)
			_cyl(0.0, 0.05, 0.18, Color(0.2, 0.05, 0.05), Vector3(0, 0.33, 0), head)
		"fn_cap":
			_cyl(0.05, 0.21, 0.16, Color(0.35, 0.12, 0.08), Vector3(0, 0.22, 0), head)
		"fn_officer":
			_sph(0.21, Color(0.25, 0.08, 0.06), Vector3(0, 0.12, 0), head, true)
			_box(Vector3(0.08, 0.25, 0.25), Color(0.9, 0.7, 0.2), Vector3(0, 0.33, 0), head)
		"yuyan":
			_sph(0.19, Color(0.1, 0.05, 0.05), Vector3(0, 0.12, 0), head, true)
			_box(Vector3(0.3, 0.08, 0.05), Color(0.6, 0.1, 0.1), Vector3(0, 0.1, 0.16), head)
		"ek_hat":
			_cyl(0.06, 0.32, 0.16, Color(0.3, 0.45, 0.25), Vector3(0, 0.26, 0), head, Vector3.ZERO, 10)
		"straw_hat":
			_cyl(0.02, 0.38, 0.14, Color(0.8, 0.7, 0.4), Vector3(0, 0.27, 0), head, Vector3.ZERO, 10)
		"ek_helm":
			_sph(0.21, Color(0.22, 0.35, 0.18), Vector3(0, 0.12, 0), head, true)
			_cyl(0.32, 0.32, 0.03, Color(0.85, 0.75, 0.35), Vector3(0, 0.13, 0), head, Vector3.ZERO, 10)
		"censor":
			_box(Vector3(0.3, 0.14, 0.3), Color(0.08, 0.08, 0.09), Vector3(0, 0.24, 0), head)
		"hamakaze":
			_cyl(0.215, 0.215, 0.05, Color(0.94, 0.93, 0.9), Vector3(0, 0.12, 0), head, Vector3.ZERO, 12)
		"parka", "wt_helm":
			var hood := _sph(0.23, body_c, Vector3(0, 0.1, -0.02), head)
			hood.scale = Vector3(1.0, 1.05, 1.0)
			var face := _sph(0.15, Color(0.95, 0.95, 0.95), Vector3(0, 0.08, 0.1), head)
			face.scale = Vector3(1.0, 1.0, 0.4)
		"warpaint":
			_box(Vector3(0.12, 0.08, 0.06), hair, Vector3(0, 0.27, -0.05), head)
			_box(Vector3(0.28, 0.04, 0.03), Color(0.1, 0.1, 0.1), Vector3(0, 0.12, 0.16), head)
		"wolf":
			var w := _sph(0.21, Color(0.55, 0.55, 0.58), Vector3(0, 0.15, 0), head, true)
			w.scale = Vector3(1, 1, 1.1)
			_cyl(0.0, 0.05, 0.14, Color(0.55, 0.55, 0.58), Vector3(0.1, 0.33, 0), head)
			_cyl(0.0, 0.05, 0.14, Color(0.55, 0.55, 0.58), Vector3(-0.1, 0.33, 0), head)
		"topknot":
			_sph(0.175, hair, Vector3(0, 0.12, -0.02), head, true)
			_sph(0.07, hair, Vector3(0, 0.3, -0.03), head)
		"bandana":
			_sph(0.18, Color(0.55, 0.1, 0.1), Vector3(0, 0.12, 0), head, true)
		"pirate_hat":
			_cyl(0.18, 0.3, 0.12, Color(0.1, 0.08, 0.08), Vector3(0, 0.28, 0), head)
		"sand_wrap":
			_sph(0.2, Color(0.8, 0.7, 0.5), Vector3(0, 0.12, 0), head, true)
			_box(Vector3(0.3, 0.1, 0.05), Color(0.8, 0.7, 0.5), Vector3(0, 0.02, 0.15), head)
		"arrow":
			_box(Vector3(0.05, 0.02, 0.3), Color(0.2, 0.5, 0.9), Vector3(0, 0.25, 0.0), head)
		_:
			_sph(0.175, hair, Vector3(0, 0.12, -0.02), head, true)

static func _weapon(model: String, n: Node3D, trim: Color) -> void:
	var steel := Color(0.78, 0.8, 0.85)
	var wood := Color(0.45, 0.3, 0.15)
	match model:
		"sword", "space_sword":
			var blade_c := steel if model == "sword" else Color(0.15, 0.15, 0.2)
			_box(Vector3(0.05, 0.03, 0.85), blade_c, Vector3(0, 0, 0.55), n)
			_box(Vector3(0.2, 0.05, 0.04), trim, Vector3(0, 0, 0.12), n)
			_box(Vector3(0.04, 0.04, 0.18), wood, Vector3(0, 0, 0.0), n)
		"dao", "dual_dao", "machete":
			_box(Vector3(0.1, 0.025, 0.75), steel, Vector3(0.02, 0, 0.5), n)
			_box(Vector3(0.16, 0.05, 0.04), trim, Vector3(0, 0, 0.12), n)
			_box(Vector3(0.04, 0.04, 0.18), wood, Vector3(0, 0, 0.0), n)
		"hooks":
			_box(Vector3(0.04, 0.03, 0.8), steel, Vector3(0, 0, 0.5), n)
			_box(Vector3(0.18, 0.03, 0.04), steel, Vector3(0.08, 0, 0.9), n)
		"spear":
			_cyl(0.025, 0.025, 2.2, wood, Vector3(0, 0, 0.6), n, Vector3(90, 0, 0), 5)
			_cyl(0.0, 0.05, 0.25, steel, Vector3(0, 0, 1.8), n, Vector3(90, 0, 0), 5)
		"guan_dao":
			_cyl(0.03, 0.03, 2.2, wood, Vector3(0, 0, 0.6), n, Vector3(90, 0, 0), 5)
			_box(Vector3(0.18, 0.03, 0.5), steel, Vector3(0.06, 0, 1.85), n)
		"staff":
			_cyl(0.03, 0.03, 2.0, wood, Vector3(0, 0, 0.4), n, Vector3(90, 0, 0), 5)
		"club":
			_cyl(0.06, 0.035, 0.7, Color(0.85, 0.82, 0.75), Vector3(0, 0, 0.35), n, Vector3(90, 0, 0), 6)
		"axe":
			_cyl(0.025, 0.025, 0.8, wood, Vector3(0, 0, 0.35), n, Vector3(90, 0, 0), 5)
			_box(Vector3(0.22, 0.03, 0.18), steel, Vector3(0.1, 0, 0.65), n)
		"knife":
			_box(Vector3(0.04, 0.02, 0.3), steel, Vector3(0, 0, 0.2), n)
		"fans":
			var f := _cyl(0.22, 0.22, 0.02, Color(0.85, 0.7, 0.2), Vector3(0, 0, 0.2), n, Vector3(0, 0, 90), 10)
			f.scale = Vector3(1, 1, 0.6)
		"bow":
			_box(Vector3(0.04, 1.1, 0.04), wood, Vector3(0, 0, 0.0), n, Vector3(0, 0, 0))
			_box(Vector3(0.01, 1.05, 0.01), Color(0.9, 0.9, 0.85), Vector3(0, 0, -0.12), n)
		"boomerang":
			_box(Vector3(0.35, 0.03, 0.07), wood, Vector3(0.12, 0, 0.1), n, Vector3(0, 30, 0))
			_box(Vector3(0.35, 0.03, 0.07), wood, Vector3(-0.12, 0, 0.1), n, Vector3(0, -30, 0))
