extends RefCounted
## Assembles fully rigged characters from the CC0 Quaternius kits:
## a base head (from Universal Base Characters), an outfit recoloured for the
## character's culture, hair, eyebrows and eyes, plus the shared animation
## libraries (Universal Animation Library 1 and 2). Everything is drawn with the
## cel shader and an ink outline to match the look of the animated series.

const TOON := preload("res://shaders/toon.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")
const Accessories = preload("res://scripts/actors/accessories.gd")
const FaceRig = preload("res://scripts/actors/face_rig.gd")

const BASE := {
	"m": "res://assets/characters/base/Superhero_Male_FullBody.gltf",
	"f": "res://assets/characters/base/Superhero_Female_FullBody.gltf",
}
const OUTFITS := {
	"m_peasant": "res://assets/characters/outfits/Male_Peasant.gltf",
	"f_peasant": "res://assets/characters/outfits/Female_Peasant.gltf",
	"m_ranger": "res://assets/characters/outfits/Male_Ranger.gltf",
	"f_ranger": "res://assets/characters/outfits/Female_Ranger.gltf",
}
const HAIR_DIR := "res://assets/characters/hair/"
const CULTURE_TEX := "res://assets/characters/culture/%s_%s.jpg"
const ANIM_LIBS := {
	"ual1": "res://assets/animations/UAL1_Standard.glb",
	"ual2": "res://assets/animations/UAL2_Standard.glb",
}

# Skin tones from light to deep (sampled from the show's palette range)
const SKIN_TONES := [
	Color(0.98, 0.85, 0.74), Color(0.93, 0.76, 0.62), Color(0.84, 0.64, 0.48),
	Color(0.72, 0.51, 0.36), Color(0.58, 0.39, 0.26), Color(0.44, 0.29, 0.19),
]

const PALETTES := {
	"earth": {"primary": Color(0.3, 0.46, 0.22), "secondary": Color(0.55, 0.45, 0.25), "accent": Color(0.85, 0.7, 0.3)},
	"fire": {"primary": Color(0.6, 0.1, 0.08), "secondary": Color(0.15, 0.08, 0.08), "accent": Color(0.92, 0.7, 0.22)},
	"water": {"primary": Color(0.16, 0.33, 0.62), "secondary": Color(0.9, 0.92, 0.95), "accent": Color(0.7, 0.8, 0.95)},
	"south": {"primary": Color(0.2, 0.36, 0.6), "secondary": Color(0.5, 0.4, 0.3), "accent": Color(0.9, 0.9, 0.88)},
	"air": {"primary": Color(0.94, 0.55, 0.12), "secondary": Color(0.98, 0.8, 0.28), "accent": Color(0.3, 0.55, 0.85)},
	"kyoshi": {"primary": Color(0.15, 0.45, 0.25), "secondary": Color(0.85, 0.68, 0.2), "accent": Color(0.95, 0.8, 0.3)},
	"sand": {"primary": Color(0.75, 0.62, 0.4), "secondary": Color(0.45, 0.22, 0.14), "accent": Color(0.3, 0.3, 0.55)},
	"outlaw": {"primary": Color(0.33, 0.22, 0.3), "secondary": Color(0.25, 0.2, 0.16), "accent": Color(0.6, 0.15, 0.12)},
	"swamp": {"primary": Color(0.32, 0.38, 0.2), "secondary": Color(0.35, 0.26, 0.16), "accent": Color(0.7, 0.7, 0.3)},
	"omashu": {"primary": Color(0.38, 0.48, 0.2), "secondary": Color(0.45, 0.3, 0.52), "accent": Color(0.8, 0.68, 0.35)},
}

static var _libs := {}
static var _head_cache := {}
static var _outline_mat: ShaderMaterial
static var _tex_cache := {}

static func outline_material() -> ShaderMaterial:
	if _outline_mat == null:
		_outline_mat = ShaderMaterial.new()
		_outline_mat.shader = OUTLINE
	return _outline_mat

static func animation_libraries() -> Dictionary:
	if _libs.is_empty():
		for key in ANIM_LIBS:
			var scene: Node = load(ANIM_LIBS[key]).instantiate()
			var ap: AnimationPlayer = scene.find_child("AnimationPlayer", true, false)
			var lib: AnimationLibrary = ap.get_animation_library("")
			for n in lib.get_animation_list():
				var a: Animation = lib.get_animation(n)
				if n.ends_with("_Loop") or n in ["Sword_Idle", "Idle_Shield_Loop"]:
					a.loop_mode = Animation.LOOP_LINEAR
			_libs[key] = lib
			scene.free()
	return _libs

static func _tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[path]

## A toon material based on an existing material's albedo texture.
static func toon_from(mat: Material, opts: Dictionary = {}) -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	sm.shader = TOON
	var tex: Texture2D = null
	if mat is BaseMaterial3D:
		tex = mat.albedo_texture
	if opts.has("texture"):
		tex = opts.texture
	sm.set_shader_parameter("albedo_tex", tex)
	sm.set_shader_parameter("albedo_tex_b", tex)
	sm.set_shader_parameter("tint", opts.get("tint", Color.WHITE))
	sm.set_shader_parameter("saturation", opts.get("saturation", 1.12))
	if opts.get("outline", true):
		sm.next_pass = outline_material()
	return sm

## Skin uses a desaturated texture multiplied by a chosen skin colour so every
## body part (head from one kit, hands from another) matches exactly.
static func skin_material(mat: Material, skin: Color) -> ShaderMaterial:
	var sm := toon_from(mat, {"tint": skin * 1.55, "saturation": 1.0})
	sm.set_shader_parameter("texture_desaturate", 1.0)
	sm.set_shader_parameter("shadow_tint", Color(0.78, 0.55, 0.6))
	return sm

static func _bind_names(mi: MeshInstance3D, skel: Skeleton3D) -> Array:
	var out := []
	var skin: Skin = mi.skin
	for i in skin.get_bind_count():
		var n := String(skin.get_bind_name(i))
		if n == "":
			n = skel.get_bone_name(skin.get_bind_bone(i))
		out.append(n)
	return out

## Keep only the head and neck of a full-body mesh (outfits cover the rest).
static func _head_only(mi: MeshInstance3D, skel: Skeleton3D, key: String) -> ArrayMesh:
	if _head_cache.has(key):
		return _head_cache[key]
	var src: ArrayMesh = mi.mesh
	var arrays := src.surface_get_arrays(0)
	var names := _bind_names(mi, skel)
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var vcount: int = arrays[Mesh.ARRAY_VERTEX].size()
	var stride := bones.size() / vcount
	var is_head := PackedByteArray()
	is_head.resize(vcount)
	for v in vcount:
		var best := 0
		var bw := -1.0
		for k in stride:
			if weights[v * stride + k] > bw:
				bw = weights[v * stride + k]
				best = bones[v * stride + k]
		var bn: String = names[best] if best < names.size() else ""
		is_head[v] = 1 if bn in ["Head", "neck_01"] else 0
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var kept := PackedInt32Array()
	for t in range(0, idx.size(), 3):
		if is_head[idx[t]] + is_head[idx[t + 1]] + is_head[idx[t + 2]] >= 2:
			kept.append(idx[t])
			kept.append(idx[t + 1])
			kept.append(idx[t + 2])
	arrays[Mesh.ARRAY_INDEX] = kept
	for c in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3]:
		arrays[c] = null
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if stride == 8 else 0)
	out.surface_set_material(0, src.surface_get_material(0))
	_head_cache[key] = out
	return out

## Move the skinned meshes of another imported scene onto our skeleton.
static func _graft(scene_path: String, skel: Skeleton3D, filter: Callable = Callable()) -> Array:
	var src: Node = load(scene_path).instantiate()
	var meshes := []
	for mi in src.find_children("*", "MeshInstance3D", true, false):
		if filter.is_valid() and not filter.call(String(mi.name)):
			continue
		mi.owner = null
		mi.get_parent().remove_child(mi)
		skel.add_child(mi)
		mi.skeleton = NodePath("..")
		meshes.append(mi)
	src.free()
	return meshes

## look: {sex, skin (0..5 or Color), hair, hair_color, beard, eye_color, outfit,
##        culture, hood, pauldrons, accessory, height, build}
static func build(look: Dictionary) -> Dictionary:
	var sex: String = look.get("sex", "m")
	var root: Node3D = load(BASE[sex]).instantiate()
	var skel: Skeleton3D = root.find_child("Skeleton3D", true, false)
	var skin_c: Color = look.skin if look.get("skin") is Color else SKIN_TONES[clampi(int(look.get("skin", 2)), 0, 5)]
	var hair_c: Color = look.get("hair_color", Color(0.1, 0.07, 0.05))
	var eye_c: Color = look.get("eye_color", Color(0.45, 0.3, 0.18))
	var parts := {"root": root, "skeleton": skel, "meshes": []}
	# Head, eyes, brows from the base character
	for mi in skel.get_children():
		if not mi is MeshInstance3D:
			continue
		var n := String(mi.name)
		if n.begins_with("SuperHero") or n.begins_with("Superhero"):
			mi.mesh = _head_only(mi, skel, sex)
			mi.set_surface_override_material(0, skin_material(mi.mesh.surface_get_material(0), skin_c))
			parts.head = mi
		elif n == "Eyes":
			mi.set_surface_override_material(0, toon_from(mi.mesh.surface_get_material(0), {"tint": Color(1, 1, 1).lerp(eye_c * 1.6, 0.55), "outline": false}))
			parts.eyes = mi
		elif n == "Eyebrows":
			mi.set_surface_override_material(0, toon_from(mi.mesh.surface_get_material(0), {"tint": hair_c * 1.4, "saturation": 0.5, "outline": false}))
			parts.brows = mi
	# Outfit
	var outfit: String = look.get("outfit", "peasant")
	var culture: String = look.get("culture", "earth")
	var keep_hood: bool = look.get("hood", false) or look.get("accessory", "") in ["parka", "wt_helm", "sand_wrap"]
	var keep_pauldrons: bool = look.get("pauldrons", false)
	var outfit_meshes := _graft(OUTFITS["%s_%s" % [sex, outfit]], skel, func(n):
		if n.find("Hood") >= 0:
			return keep_hood
		if n.find("Pauldron") >= 0:
			return keep_pauldrons
		return true)
	var cloth_tex := _tex(CULTURE_TEX % [outfit, culture])
	for mi in outfit_meshes:
		for s in mi.mesh.get_surface_count():
			var m: Material = mi.mesh.surface_get_material(s)
			var mname := m.resource_name if m else ""
			if String(mi.name).find("Hood") >= 0 and look.get("accessory", "") in ["parka", "wt_helm"]:
				mi.set_surface_override_material(s, toon_from(m, {"texture": cloth_tex, "tint": Color(0.75, 0.85, 1.25)}))
			elif mname.find("Regular") >= 0:
				mi.set_surface_override_material(s, skin_material(m, skin_c))
			else:
				mi.set_surface_override_material(s, toon_from(m, {"texture": cloth_tex}))
	parts.meshes.append_array(outfit_meshes)
	# Hair, beard
	var hair: String = look.get("hair", "Hair_SimpleParted")
	var hair_list := []
	if hair != "":
		hair_list.append(hair)
	if look.get("beard", false) and sex == "m":
		hair_list.append("Hair_Beard")
	for h in hair_list:
		for mi in _graft(HAIR_DIR + h + ".gltf", skel):
			var hm := toon_from(mi.mesh.surface_get_material(0), {"tint": hair_c * 2.4 + Color(0.04, 0.04, 0.04), "saturation": 1.0})
			hm.set_shader_parameter("texture_desaturate", 1.0)
			mi.set_surface_override_material(0, hm)
			parts.meshes.append(mi)
	# Culture garments and headwear
	var palette: Dictionary = PALETTES.get(culture, PALETTES.earth)
	if look.get("accessory", "") != "":
		Accessories.dress_head(parts, look.accessory, sex, hair_c, palette)
	if look.get("kit", "") != "":
		Accessories.dress_body(parts, look.kit, sex, palette)
	# Hand attachments for weapons
	for side in ["r", "l"]:
		var h := BoneAttachment3D.new()
		h.bone_name = "hand_" + side
		skel.add_child(h)
		parts["hand_" + side] = h
	# Facial expressions
	if parts.has("head"):
		FaceRig.setup(parts)
	# Proportions
	var hgt: float = look.get("height", 1.0)
	root.scale = Vector3(hgt, hgt, hgt)
	# Animation
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	root.add_child(ap)
	for key in animation_libraries():
		ap.add_animation_library(key, _libs[key])
	parts.anim = ap
	return parts

## Random appearance for a member of a culture.
static func random_look(culture: String, rng: RandomNumberGenerator = null, force_sex: String = "") -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var sex := "m" if rng.randf() < 0.55 else "f"
	if force_sex != "":
		sex = force_sex
	var skin := 2
	var hair_c := Color(0.08, 0.06, 0.05)
	var eye := Color(0.35, 0.25, 0.15)
	match culture:
		"fire":
			skin = rng.randi_range(0, 2)
			eye = Color(0.85, 0.6, 0.15)
		"earth", "kyoshi", "omashu":
			skin = rng.randi_range(1, 4)
			eye = [Color(0.3, 0.45, 0.2), Color(0.4, 0.28, 0.16)][rng.randi() % 2]
		"water", "south":
			skin = rng.randi_range(3, 5)
			eye = Color(0.25, 0.5, 0.85)
			hair_c = Color(0.12, 0.08, 0.05)
		"air":
			skin = rng.randi_range(1, 3)
			eye = Color(0.45, 0.45, 0.5)
		"sand":
			skin = rng.randi_range(2, 4)
		"swamp":
			skin = rng.randi_range(2, 5)
	var hairs := ["Hair_SimpleParted", "Hair_Buzzed", "Hair_Long"] if sex == "m" else ["Hair_Buns", "Hair_Long", "Hair_BuzzedFemale"]
	var hair: String = hairs[rng.randi() % hairs.size()]
	if culture == "air":
		hair = ""   # monks and nuns shave their heads
	return {"sex": sex, "skin": skin, "hair": hair, "hair_color": hair_c, "eye_color": eye,
		"beard": sex == "m" and rng.randf() < 0.25, "culture": culture, "height": rng.randf_range(0.94, 1.05)}
