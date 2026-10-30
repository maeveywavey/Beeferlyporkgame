extends Node3D
## Real-time 3D battle: spawns both sides from GS.pending_battle, runs combat,
## and reports casualties back to the world.

const Unit = preload("res://scripts/battle/unit.gd")
const Projectile = preload("res://scripts/battle/projectile.gd")
const Bending = preload("res://scripts/battle/bending.gd")
const UI = preload("res://scripts/ui/ui.gd")
const MB = preload("res://scripts/world/map_builder.gd")
const Roster = preload("res://scripts/core/roster.gd")
const SettingsWindow = preload("res://scripts/ui/settings_window.gd")
const Dress = preload("res://scripts/battle/set_dressing.gd")
const Land = preload("res://scripts/battle/landscape.gd")
const Arch = preload("res://scripts/town/arch.gd")
const ActorS = preload("res://scripts/actors/actor.gd")
const FieldEffects = preload("res://scripts/battle/field_effects.gd")
const LooksS = preload("res://scripts/actors/looks.gd")

const HALF := 80.0
const GRID := 161
const SPAWN_Z := 55.0

static var autotest := false
static var autotest_return := false

var fire_mult := 1.0
var water_mult := 1.0
var biome := "grass"
var hour := 12.0
var units: Array = []
var team_units: Array = [[], []]
var reserves: Array = [[], []]
var active_cap: Array = [40, 40]
var player_unit = null
var player_controlled := true
var player_ranged_mode := false
var casualties := {}
var companions_down: Array = []
var player_downed := false
var battle_over := false
var winner := -1
var obstacles: Array = []
var walls: Array = []
var siege := ""
var arena := -1
var duel := ""          # lord id for an Agni Kai
var wall_z := 0.0
var breach_half := 6.0
var heights := PackedFloat32Array()
var player_kills := 0
## Seconds before anyone may attack: an arena countdown, or a moment to take
## in the field before the first volley.
var opening_t := 0.0
var _opening_said := -1
var weather: CPUParticles3D
var weather_kind := ""
## What bending leaves on the ground: fire, water, rocks, walls and pillars.
var field
var _reinforce_t := 2.0
var _sep_t := 0.0
var _finished := false
var _autotest_t := 0.0

# Camera
var cam: Camera3D
var cam_yaw := 0.0
var cam_pitch := -0.25
var cam_dist := 1.5
var cam_far := false
var mouse_accum := Vector2.ZERO
var spectate_target = null

# HUD
var hud: CanvasLayer
var hp_bar: ProgressBar
var chi_bar: ProgressBar
var mount_bar: ProgressBar
var info_label: Label
var count_label: Label
var feed: VBoxContainer
var big_label: Label
var note_label: Label
var pause_panel: Control
var crosshair: Control
var _note_t := 0.0
var paused := false

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
func _ready() -> void:
	Music.play("battle")
	Engine.time_scale = 1.0
	if GS.pending_battle.is_empty():
		_debug_setup()
	var b: Dictionary = GS.pending_battle
	fire_mult = b.get("fire_mult", 1.0)
	water_mult = b.get("water_mult", 1.0)
	biome = b.get("biome", "grass")
	if biome in ["ocean", "beach"]:
		biome = "beach"
	hour = b.get("hour", 12.0)
	siege = b.get("siege", "")
	arena = b.get("arena", -1)
	duel = b.get("duel", "")
	if siege != "":
		wall_z = 28.0 if b.player_attacking else -28.0
	_build_heights()
	_plan_landscape()
	_build_environment()
	_build_ground()
	if arena >= 0 or duel != "":
		_build_arena()
	else:
		_build_props()
	if siege != "":
		_build_siege_walls()
	field = FieldEffects.new()
	add_child(field)
	field.setup(self, biome if arena < 0 and duel == "" else "desert", weather_kind == "rain")
	_build_hud()
	cam = Camera3D.new()
	cam.fov = 70.0
	cam.far = 600.0
	add_child(cam)
	if duel != "":
		_spawn_duel()
	elif arena >= 0:
		_spawn_arena()
	else:
		_prepare_sides(b)
		_initial_spawn()
	opening_t = 3.0 if (arena >= 0 or duel != "") else 2.0
	if not autotest:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		player_controlled = false
		Engine.time_scale = 4.0
	Sfx.play("horn", -6.0)
	var msg := "The battle begins!"
	if fire_mult == 0.0:
		msg += " The sun is dark — firebenders are powerless!"
	elif fire_mult > 1.6:
		msg += " The Great Comet burns overhead — firebending is at its peak!"
	if weather_kind == "rain":
		msg += " Rain is falling: fire gutters and water swells."
	elif weather_kind == "snow":
		msg += " Snow is falling: fire burns low, water runs strong."
	if water_mult == 0.0:
		msg += " The moon is eclipsed — waterbenders are powerless!"
	elif water_mult > 1.4:
		msg += " The full moon empowers waterbenders."
	feed_msg(msg, Color(1, 0.9, 0.5))

func _debug_setup() -> void:
	if not GS.game_active:
		var p := GS.create_player("Tester", "ek_refugee", "earth", Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
		GS.new_game(p)
		Roster.add(GS.player_party().roster, "ek_soldier", 10)
		Roster.add(GS.player_party().roster, "ek_archer", 5)
		Roster.add(GS.player_party().roster, "ek_earthbender", 4)
	var e := GS.make_party("", "Test Enemies", "bandit", "fire_nation", GS.player_party().pos)
	Roster.add(e.roster, "fn_soldier", 10)
	Roster.add(e.roster, "fn_firebender", 6)
	Roster.add(e.roster, "fn_archer", 4)
	Roster.add(e.roster, "fn_rhino_rider", 3)
	GS.pending_battle = {"enemies": [e.id], "allies": [], "siege": "", "player_attacking": true, "biome": "grass",
		"hour": 14.0, "fire_mult": 1.15, "water_mult": 0.95, "enemy_garrison": false, "ally_garrison": false}

# ---------------------------------------------------------------------------
# Terrain
# ---------------------------------------------------------------------------
func _build_heights() -> void:
	heights.resize(GRID * GRID)
	var n := FastNoiseLite.new()
	n.seed = randi()
	n.frequency = 0.015
	n.fractal_octaves = 3
	var amp := 2.0
	match biome:
		"mountain": amp = 5.0
		"highland": amp = 3.5
		"desert": amp = 3.0
		"volcanic": amp = 3.0
		"swamp", "beach": amp = 0.6
		"snow": amp = 1.8
		"forest": amp = 1.6
	for gz in GRID:
		for gx in GRID:
			var x := gx - HALF
			var z := gz - HALF
			var h := n.get_noise_2d(x, z) * amp
			if arena >= 0 or duel != "":
				h = 0.0 if Vector2(x, z).length() < 16.0 else minf(6.0, (Vector2(x, z).length() - 16.0) * 0.8)
			# keep spawn areas smoother
			var edge := clampf((absf(z) - 40.0) / 20.0, 0.0, 1.0)
			h *= 1.0 - edge * 0.5
			# slope up near the field border so it feels enclosed
			var border := maxf(absf(x), absf(z))
			if border > 70.0:
				h += (border - 70.0) * 0.6
			if siege != "":
				var dz := (z - wall_z) * signf(wall_z)
				if dz > 1.0 and dz < 5.0:
					h = 3.0
				elif dz >= 5.0 and dz < 9.0:
					h = lerpf(3.0, h, (dz - 5.0) / 4.0)
				elif absf(dz) <= 1.0:
					h = maxf(h, 0.0)
			heights[gz * GRID + gx] = h

func ground_height(x: float, z: float) -> float:
	var fx := clampf(x + HALF, 0.0, GRID - 1.001)
	var fz := clampf(z + HALF, 0.0, GRID - 1.001)
	var x0 := int(fx)
	var z0 := int(fz)
	var tx := fx - x0
	var tz := fz - z0
	var a := heights[z0 * GRID + x0]
	var b := heights[z0 * GRID + x0 + 1]
	var c := heights[(z0 + 1) * GRID + x0]
	var d := heights[(z0 + 1) * GRID + x0 + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)

func _biome_ground_color() -> Color:
	match biome:
		"snow": return Color(0.9, 0.93, 0.97)
		"desert": return Color(0.85, 0.74, 0.5)
		"forest": return Color(0.3, 0.45, 0.2)
		"swamp": return Color(0.3, 0.36, 0.22)
		"volcanic": return Color(0.33, 0.27, 0.24)
		"mountain": return Color(0.48, 0.45, 0.4)
		"beach": return Color(0.82, 0.76, 0.56)
		"highland": return Color(0.45, 0.52, 0.32)
	return Color(0.4, 0.55, 0.26)

## Where groves, cliffs and scrub go (scripts/battle/landscape.gd), decided
## before the ground is built so the ground can show what grows on it.
var land_items: Array = []
var _land_rng := RandomNumberGenerator.new()
var _stain := {}

func _plan_landscape() -> void:
	if arena >= 0 or duel != "":
		return
	if GS.pending_battle.has("seed"):
		_land_rng.seed = int(GS.pending_battle.seed)
	else:
		_land_rng.randomize()
	land_items = Land.layout(biome, _land_rng, wall_z if siege != "" else 999.0)
	# 8 m buckets of trees and cliffs, for staining the ground near them
	for it in land_items:
		if it.kind in ["tree", "cliff", "boulder"]:
			var k := Vector2i(floori(it.pos.x / 8.0), floori(it.pos.y / 8.0))
			if not _stain.has(k):
				_stain[k] = []
			_stain[k].append(it)

## Ground colour at a point for the terrain shader: rgb multiplies the ground
## (stony grey-brown at cliff feet), alpha is how much leaf litter lies there
## (under trees); the shader breaks the litter into hard-edged clumps.
func _ground_stain(x: float, z: float) -> Color:
	var c := Color(1, 1, 1, 0)
	var k := Vector2i(floori(x / 8.0), floori(z / 8.0))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for it in _stain.get(k + Vector2i(dx, dz), []):
				var d: float = Vector2(x, z).distance_to(it.pos)
				if it.kind == "tree":
					c.a = maxf(c.a, clampf(1.0 - d / 6.0, 0.0, 1.0))
				else:
					var near := clampf(1.0 - (d - float(it.r)) / 4.0, 0.0, 1.0)
					var t := Color(1.0, 1.0, 1.0).lerp(Color(1.1, 0.95, 0.85), near * 0.6)
					c = Color(t.r, t.g, t.b, c.a)
	return c

func _build_ground() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := _biome_ground_color()
	var cn := FastNoiseLite.new()
	cn.seed = 5
	cn.frequency = 0.06
	var step := 2
	var cols := []
	var verts := []
	var n := int((GRID - 1) / step) + 1
	for iz in n:
		for ix in n:
			var gx := ix * step
			var gz := iz * step
			var h := heights[gz * GRID + gx]
			verts.append(Vector3(gx - HALF, h, gz - HALF))
			var v := cn.get_noise_2d(gx, gz) * 0.12
			var stain := _ground_stain(gx - HALF, gz - HALF)
			var c := Color((1.0 + v) * stain.r, (1.0 + v) * stain.g, (1.0 + v * 0.6) * stain.b, stain.a)
			if siege != "" and absf(gz - HALF - wall_z) < 9.0:
				c = c.lerp(Color(0.85, 0.78, 0.7, c.a), 0.5)
			cols.append(c)
	for iz in n - 1:
		for ix in n - 1:
			var i0 := iz * n + ix
			for idx in [i0, i0 + 1, i0 + n, i0 + 1, i0 + n + 1, i0 + n]:
				st.set_color(cols[idx])
				st.add_vertex(verts[idx])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	# textured, desaturated ground (scripts/battle/landscape.gd)
	mi.material_override = Land.ground_material(biome)
	add_child(mi)
	# Distant ground and painted mountains
	var far := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(900, 900)
	far.mesh = pm
	far.position = Vector3(0, -6.0, 0)
	var fm: ShaderMaterial = Land.ground_material(biome).duplicate()
	fm.set_shader_parameter("tint", Color(0.85, 0.85, 0.85))
	far.material_override = fm
	add_child(far)
	# mountains painted on cards around the field, as PS1 games did
	var daylight := clampf(sin((hour - 6.0) / 13.0 * PI), 0.0, 1.0)
	add_child(Land.backdrop(biome, Color(0.2, 0.2, 0.3).lerp(Color(0.75, 0.8, 0.9), daylight)))

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	var daylight := clampf(sin((hour - 6.0) / 13.0 * PI), 0.0, 1.0)
	if fire_mult == 0.0:
		daylight = 0.12
	sm.sky_top_color = Color(0.08, 0.1, 0.22).lerp(Color(0.3, 0.5, 0.85), daylight)
	sm.sky_horizon_color = Color(0.2, 0.2, 0.3).lerp(Color(0.75, 0.8, 0.9), daylight)
	sm.ground_horizon_color = sm.sky_horizon_color
	sm.ground_bottom_color = Color(0.2, 0.18, 0.15)
	if fire_mult > 2.0:
		sm.sky_top_color = sm.sky_top_color.lerp(Color(0.7, 0.15, 0.05), 0.6)
		sm.sky_horizon_color = sm.sky_horizon_color.lerp(Color(1.0, 0.45, 0.2), 0.6)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.75).lerp(Color(0.8, 0.8, 0.8), daylight)
	env.ambient_light_energy = 0.45 + daylight * 0.35
	env.fog_enabled = true
	env.fog_light_color = sm.sky_horizon_color
	env.fog_density = 0.004 if biome != "swamp" else 0.02
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-20.0 - daylight * 45.0, 30.0 + hour * 5.0, 0)
	sun.light_energy = 0.25 + daylight * 1.0
	sun.light_color = Color(0.65, 0.72, 1.0) if daylight < 0.05 else Color(1, 0.95, 0.88)
	if fire_mult > 2.0:
		sun.light_color = Color(1.0, 0.6, 0.4)
	# Real-time shadows over-brighten the Compatibility renderer; units use blob shadows instead.
	sun.shadow_enabled = false
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)
	_build_weather()

func _build_weather() -> void:
	var kind := ""
	if biome == "snow":
		kind = "snow"
	elif biome in ["swamp", "forest", "grass"] and randf() < 0.25 and not OS.has_environment("NO_WEATHER"):
		kind = "rain"
	elif biome == "desert" and randf() < 0.3:
		kind = "dust"
	weather_kind = kind
	# rain smothers fire and feeds water; snow does the same, a little
	if kind == "rain":
		fire_mult *= 0.7
		water_mult *= 1.25
	elif kind == "snow":
		fire_mult *= 0.9
		water_mult *= 1.1
	if kind == "":
		return
	weather = CPUParticles3D.new()
	weather.amount = 700 if kind != "dust" else 250
	weather.lifetime = 3.0 if kind == "snow" else 1.2
	weather.local_coords = false
	weather.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	weather.emission_box_extents = Vector3(30, 1, 30)
	weather.direction = Vector3(0, -1, 0)
	weather.spread = 10.0
	var mesh := BoxMesh.new()
	var col := Color(1, 1, 1)
	match kind:
		"snow":
			mesh.size = Vector3(0.06, 0.06, 0.06)
			weather.gravity = Vector3(0.5, -2.5, 0)
			weather.initial_velocity_min = 1.0
			weather.initial_velocity_max = 2.0
		"rain":
			mesh.size = Vector3(0.015, 0.5, 0.015)
			weather.gravity = Vector3(0, -25, 0)
			weather.initial_velocity_min = 10.0
			weather.initial_velocity_max = 14.0
			col = Color(0.7, 0.75, 0.85, 0.6)
		"dust":
			mesh.size = Vector3(0.12, 0.12, 0.12)
			weather.direction = Vector3(1, 0, 0)
			weather.gravity = Vector3(3, -0.3, 0)
			weather.initial_velocity_min = 4.0
			weather.initial_velocity_max = 8.0
			weather.emission_box_extents = Vector3(30, 6, 30)
			col = Color(0.85, 0.75, 0.55, 0.7)
	weather.mesh = mesh
	weather.material_override = MB.mat(col, 1.0, true)
	add_child(weather)

func _build_props() -> void:
	var rng := _land_rng
	var daylight := clampf(sin((hour - 6.0) / 13.0 * PI), 0.0, 1.0)
	var light := Color(0.45, 0.5, 0.65).lerp(Color(1.0, 0.97, 0.9), daylight)
	var pines := biome in ["snow", "mountain", "highland"] or (biome == "forest" and true)
	var dead := biome in ["desert", "beach", "volcanic"]
	for it in land_items:
		var p: Vector2 = it.pos
		if absf(p.x) > 76.0 or absf(p.y) > 46.0:
			continue
		var h := ground_height(p.x, p.y)
		var node: Node3D
		match it.kind:
			"cliff":
				node = Land.cliff(biome, it.r, it.h, rng)
				obstacles.append({"p": p, "r": it.r * 0.9})
			"boulder":
				node = Land.cliff(biome, it.r, it.r * rng.randf_range(0.7, 1.3), rng)
				obstacles.append({"p": p, "r": it.r * 0.9})
			"tree":
				if dead:
					node = Land.tree(biome, "dead", rng, light)
				elif pines and (biome != "forest" or rng.randf() < 0.4):
					node = Land.pine(biome, rng, light)
				else:
					node = Land.tree(biome, "broad", rng, light)
				node.rotation.y = rng.randf() * TAU
				obstacles.append({"p": p, "r": 0.5})
			"bush":
				if dead:
					continue
				node = Land.card(Land.leaf_card(biome, rng.randi_range(1, 3)), Vector2.ONE * rng.randf_range(1.2, 2.0), 2, light)
				node.position.y -= 0.3
			"grass":
				if biome in ["snow", "volcanic"]:
					continue
				node = Land.card(Land.grass_card(biome), Vector2.ONE * rng.randf_range(0.6, 1.1), 1, light)
		if node == null:
			continue
		node.position += Vector3(p.x, h, p.y)
		add_child(node)

func _build_arena() -> void:
	# A sunken ring of cut stone, wooden stands and a seated crowd
	var b = Arch.Builder.new()
	var segs := 28
	for i in segs:
		var a := TAU * i / segs
		var p := Vector2(cos(a), sin(a)) * 16.5
		obstacles.append({"p": p, "r": 1.9})
		var rot := -a + PI / 2.0
		b.box(Vector3(p.x, 0.35, p.y), Vector3(3.8, 0.7, 1.2), Color(0.55, 0.5, 0.42), rot)
		b.box(Vector3(p.x, 1.0, p.y), Vector3(3.7, 0.6, 1.1), Color(0.6, 0.55, 0.46), rot)
		for row in 3:
			var sp := Vector2(cos(a), sin(a)) * (20.0 + row * 2.5)
			var gy := ground_height(sp.x, sp.y)
			b.box(Vector3(sp.x, gy + 0.3 + row * 0.9, sp.y), Vector3(5.0, 0.6, 2.2), Color(0.48, 0.34, 0.2), rot)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = Arch.material(true)
	add_child(mi)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 18:
		var a2 := TAU * i / 18.0 + rng.randf() * 0.1
		var row2 := rng.randi() % 3
		var sp2 := Vector2(cos(a2), sin(a2)) * (20.0 + row2 * 2.5)
		var fan = ActorS.new()
		fan.position = Vector3(sp2.x, ground_height(sp2.x, sp2.y) + 0.6 + row2 * 0.9 - 0.45, sp2.y)
		fan.rotation.y = atan2(-sp2.x, -sp2.y)
		add_child(fan)
		fan.setup(LooksS.troop_look(["ek_peasant", "om_militia", "fn_conscript", "merc_archer"][rng.randi() % 4], rng))
		fan.call_deferred("loop", ["ual1/Sitting_Idle", "ual1/Sitting_Talking"][rng.randi() % 2])
		fan.set_expression(["happy", "laugh", "surprised", "angry"][rng.randi() % 4])
	for i in 6:
		var lp := Vector2(cos(TAU * i / 6.0), sin(TAU * i / 6.0)) * 18.0
		var light := OmniLight3D.new()
		light.light_color = Color(1, 0.75, 0.45)
		light.light_energy = 2.5
		light.omni_range = 22.0
		light.position = Vector3(lp.x, 6.0, lp.y)
		add_child(light)
		var torch := Arch.lantern(Color(1.0, 0.55, 0.2))
		torch.scale = Vector3.ONE * 2.2
		torch.position = Vector3(lp.x, 0, lp.y)
		add_child(torch)

func _spawn_arena() -> void:
	reserves = [[], []]
	active_cap = [1, 1]
	_spawn_entry({"kind": "player", "id": "player", "key": "player"}, 0, Vector3(0, 0, -12), 0.0)
	var u = Unit.new()
	u.battle = self
	u.setup_arena(Data.arena_fighters[arena], 1)
	add_child(u)
	u.position = Vector3(0, 0, 12)
	u.facing = PI
	u.rotation.y = PI
	units.append(u)
	team_units[1].append(u)
	feed_msg("Madam Gu: \"In this corner... %s!\"" % Data.arena_fighters[arena].name, Color(1, 0.85, 0.4))

## Agni Kai: the player and a Fire Nation lord face each other alone.
func _spawn_duel() -> void:
	reserves = [[], []]
	active_cap = [1, 1]
	_spawn_entry({"kind": "player", "id": "player", "key": "player"}, 0, Vector3(0, 0, -9), 0.0)
	var u = _spawn_entry({"kind": "lord", "id": duel, "key": "duel"}, 1, Vector3(0, 0, 9), PI)
	feed_msg("Agni Kai! %s bows, then drops into a fighting stance." % Data.lords[duel].name, Color(1, 0.7, 0.35))

func _build_siege_walls() -> void:
	var culture: String = Data.settlements[siege].culture
	var pal := MB.culture_palette(culture)
	var wc: Color = pal.wall
	var thick := 1.6
	var h := 5.0
	for side in [-1, 1]:
		var x0 = breach_half * side
		var x1 = (HALF - 2.0) * side
		var cx = (x0 + x1) / 2.0
		var length := absf(x1 - x0)
		var seg := MB.box(Vector3(length, h, thick), wc, Vector3(cx, h / 2.0 - 1.0, wall_z))
		add_child(seg)
		var n := int(length / 2.0)
		for i in n:
			if i % 2 == 0:
				add_child(MB.box(Vector3(1.0, 0.8, thick * 0.6), wc, Vector3(x0 + side * (i * 2.0 + 1.0), h - 0.6, wall_z - signf(wall_z) * thick * 0.2)))
		walls.append({"c": Vector2(cx, wall_z), "axis": Vector2(1, 0), "hl": length / 2.0, "ht": thick / 2.0, "h": 3.6, "until": INF, "node": seg})
		# tower at the breach
		var tower := MB.box(Vector3(3.5, h + 2.5, 3.5), wc.darkened(0.1), Vector3(x0 + side * 1.8, (h + 2.5) / 2.0 - 1.0, wall_z))
		add_child(tower)
		walls.append({"c": Vector2(x0 + side * 1.8, wall_z), "axis": Vector2(1, 0), "hl": 1.75, "ht": 1.75, "h": h + 1.5, "until": INF, "node": tower})
	# Rubble in the breach
	for i in 5:
		add_child(MB.sphere(randf_range(0.4, 0.8), wc.darkened(0.2), Vector3(randf_range(-breach_half + 1.5, breach_half - 1.5), ground_height(0, wall_z), wall_z + randf_range(-1.5, 1.5))))

# ---------------------------------------------------------------------------
# Sides
# ---------------------------------------------------------------------------
func _entries_for_party(pid: String) -> Array:
	var out := []
	if not GS.parties.has(pid):
		return out
	var p: Dictionary = GS.parties[pid]
	if p.lord != "":
		out.append({"kind": "lord", "id": p.lord, "key": pid})
	var troops := []
	for s in p.roster:
		for i in s.n - s.w:
			troops.append({"kind": "troop", "id": s.id, "key": pid})
	troops.shuffle()
	out.append_array(troops)
	return out

func _entries_for_garrison(sid: String) -> Array:
	var out := []
	for s in GS.settlements[sid].garrison:
		for i in s.n - s.w:
			out.append({"kind": "troop", "id": s.id, "key": "garrison:" + sid})
	out.shuffle()
	return out

func _prepare_sides(b: Dictionary) -> void:
	var mine := []
	mine.append({"kind": "player", "id": "player", "key": "player"})
	for cid in GS.player.companions:
		if not GS.companion_state(cid).wounded:
			mine.append({"kind": "companion", "id": cid, "key": "player"})
	var my_troops := _entries_for_party("player")
	var allies := []
	for aid in b.get("allies", []):
		allies.append_array(_entries_for_party(aid))
	if b.get("ally_garrison", false):
		allies.append_array(_entries_for_garrison(b.siege))
	mine.append_array(my_troops)
	# interleave allies so reinforcements mix
	mine.append_array(allies)
	var theirs := []
	for eid in b.get("enemies", []):
		theirs.append_array(_entries_for_party(eid))
	if b.get("enemy_garrison", false):
		theirs.append_array(_entries_for_garrison(b.siege))
	# Heroes first in each list (the Avatar counts as one)
	theirs.sort_custom(func(x, y): return (x.kind == "lord" or x.id == "avatar") and not (y.kind == "lord" or y.id == "avatar"))
	reserves = [mine, theirs]
	var total := maxf(1.0, mine.size() + theirs.size())
	var bs := float(GS.settings.battle_size)
	var share := clampf(mine.size() / total, 0.3, 0.7)
	active_cap = [maxi(4, int(bs * share)), maxi(4, int(bs * (1.0 - share)))]

func _spawn_entry(e: Dictionary, team: int, pos: Vector3, face: float):
	var u = Unit.new()
	u.battle = self
	match e.kind:
		"player": u.setup_player(team)
		"companion": u.setup_companion(e.id, team)
		"lord": u.setup_lord(e.id, team, e.key)
		_: u.setup_troop(e.id, team, e.key)
	add_child(u)
	u.position = Vector3(pos.x, ground_height(pos.x, pos.z), pos.z)
	u.facing = face
	u.rotation.y = face
	u.hold_pos = u.position
	units.append(u)
	team_units[team].append(u)
	if e.id == "avatar":
		_apply_avatar_mods(u)
	if e.kind == "player":
		player_unit = u
		cam_yaw = face
	elif team == 0:
		u.add_ally_marker()
	# Archers of the defending side start on the ramparts
	if siege != "" and u.use_ranged:
		var defending_team := 1 if GS.pending_battle.player_attacking else 0
		if team == defending_team:
			u.order = "hold"
			u.hold_pos = Vector3(u.position.x, 0, wall_z + signf(wall_z) * 3.0)
	return u

## What the player prepared against the Avatar: denied ground and chi-blocker nets at
## the seat (traps), walls (fort), and a raid on their home (demoralised).
func _apply_avatar_mods(u) -> void:
	var m: Dictionary = GS.pending_battle.get("avatar", {})
	if m.is_empty():
		return
	var traps := int(m.get("traps", 0))
	var fort := int(m.get("fort", 0))
	var mult := (1.0 - 0.12 * traps) * (0.85 if m.get("demoralized", false) else 1.0)
	u.max_hp *= mult
	u.hp = u.max_hp
	u.bend_power *= 1.0 - 0.06 * fort
	if traps > 0:
		u.bend_block_t = 4.0 * traps
		hud_note("The nets and bare timber hold %s for a moment: %d seconds without bending." % [u.display_name, int(u.bend_block_t)])

## The Avatar State: a shockwave, and every eye on the field turns.
func avatar_state(u) -> void:
	if autotest:
		print("AVATAR STATE: %s at %.0f/%.0f hp, elements %s" % [u.display_name, u.hp, u.max_hp, u.avatar_elements])
	feed_msg("%s's eyes blaze white. The Avatar State!" % u.display_name, Color(0.8, 0.95, 1))
	hud_note("The Avatar State")
	_ring_fx(u.position, 7.0, Color(0.85, 0.95, 1.0))
	for o in team_units[1 - u.team]:
		if o.alive and o.dist_to(u) < 7.0:
			var dir: Vector3 = (o.position - u.position)
			dir.y = 0.0
			o.apply_damage(12.0, u, "air", dir.normalized(), 14.0, true)
	if not GS.settings.get("reduce_flashing", false):
		spawn_burst(u.position + Vector3(0, 1.2, 0), Color(0.85, 0.95, 1.0), 2.5)

func _spawn_z(team: int) -> float:
	var z := -SPAWN_Z if team == 0 else SPAWN_Z
	if siege != "":
		var defending_team := 1 if GS.pending_battle.player_attacking else 0
		if team == defending_team:
			z = wall_z + signf(wall_z) * 14.0
	return z

func _spawn_wave(team: int, count: int) -> void:
	var z := _spawn_z(team)
	var face := 0.0 if team == 0 else PI
	var dirz := 1.0 if team == 0 else -1.0
	var inf := []
	var rng_units := []
	var cav := []
	var heroes := []
	for i in count:
		if reserves[team].is_empty():
			break
		var e: Dictionary = reserves[team].pop_front()
		match e.kind:
			"player", "companion", "lord": heroes.append(e)
			_:
				var t: Dictionary = Data.troop(e.id)
				if t.mount != "":
					cav.append(e)
				elif t.ranged != "":
					rng_units.append(e)
				else:
					inf.append(e)
	var spacing := 1.6
	# heroes and infantry in the front lines
	var front := heroes + inf
	var per_row := 20
	for i in front.size():
		var row := int(i / per_row)
		var col := i % per_row
		var n_in_row := mini(per_row, front.size() - row * per_row)
		var x := (col - (n_in_row - 1) / 2.0) * spacing
		var pos := Vector3(x, 0, z + dirz * (6.0 - row * 1.8))
		if front[i].kind == "player":
			pos = Vector3(0, 0, z + dirz * 3.0)
		_spawn_entry(front[i], team, pos, face)
	for i in rng_units.size():
		var row2 := int(i / per_row)
		var col2 := i % per_row
		var n2 := mini(per_row, rng_units.size() - row2 * per_row)
		var x2 := (col2 - (n2 - 1) / 2.0) * spacing * 1.3
		_spawn_entry(rng_units[i], team, Vector3(x2, 0, z - dirz * (2.0 + row2 * 1.8)), face)
	for i in cav.size():
		var side := -1.0 if i % 2 == 0 else 1.0
		var x3 := side * (22.0 + int(i / 2) * 2.5)
		_spawn_entry(cav[i], team, Vector3(x3, 0, z + dirz * 2.0), face)

func _initial_spawn() -> void:
	for t in 2:
		_spawn_wave(t, active_cap[t])
	if player_unit == null:
		player_controlled = false

func _check_reinforcements(delta: float) -> void:
	_reinforce_t -= delta
	if _reinforce_t > 0.0:
		return
	_reinforce_t = 3.0
	for t in 2:
		var alive: int = team_units[t].size()
		if alive < active_cap[t] * 0.55 and not reserves[t].is_empty():
			var n: int = active_cap[t] - alive
			_spawn_wave(t, n)
			feed_msg("Reinforcements have arrived for %s!" % ("your side" if t == 0 else "the enemy"), Color(0.8, 0.9, 1))

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
var _prof_us := 0
var _prof_n := 0

func _physics_process(delta: float) -> void:
	if paused:
		return
	var t0 := Time.get_ticks_usec()
	for u in units:
		u.tick(delta)
	_separate()
	if autotest:
		_prof_us += Time.get_ticks_usec() - t0
		_prof_n += 1
	_update_walls()
	_tick_opening(delta)
	if not battle_over:
		_check_reinforcements(delta)
	if autotest:
		_autotest_t += delta
		if battle_over or _autotest_t > 240.0:
			if not _finished:
				_finish(false)

func _tick_opening(delta: float) -> void:
	if opening_t <= 0.0:
		return
	opening_t -= delta
	if arena < 0 and duel == "":
		return
	var n := int(ceil(opening_t))
	if n != _opening_said:
		_opening_said = n
		if n > 0:
			hud_note(str(n))
		else:
			hud_note("Fight!")
			Sfx.play("horn", -8.0)

func _process(delta: float) -> void:
	_update_camera(delta)
	if weather != null and cam != null:
		weather.global_position = cam.global_position + Vector3(0, 12.0, 0)
	_update_hud(delta)
	if player_unit != null and player_controlled and player_unit.alive and not paused:
		player_unit.facing = cam_yaw
		mouse_accum = mouse_accum.lerp(Vector2.ZERO, minf(1.0, delta * 6.0))

func _separate() -> void:
	var cell := {}
	for u in units:
		if not u.alive:
			continue
		var k := Vector2i(int(floor(u.position.x / 2.0)), int(floor(u.position.z / 2.0)))
		if not cell.has(k):
			cell[k] = []
		cell[k].append(u)
	for u in units:
		if not u.alive:
			continue
		var k := Vector2i(int(floor(u.position.x / 2.0)), int(floor(u.position.z / 2.0)))
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var kk := k + Vector2i(dx, dz)
				if not cell.has(kk):
					continue
				for o in cell[kk]:
					if o == u or o.get_instance_id() < u.get_instance_id():
						continue
					var d := Vector2(o.position.x - u.position.x, o.position.z - u.position.z)
					var min_d: float = u.radius + o.radius
					var l := d.length()
					if l < min_d and l > 0.0001:
						var push := d / l * (min_d - l)
						var wu := 0.5
						if u.mounted() and not o.mounted():
							wu = 0.15
						elif o.mounted() and not u.mounted():
							wu = 0.85
						u.position.x -= push.x * wu
						u.position.z -= push.y * wu
						o.position.x += push.x * (1.0 - wu)
						o.position.z += push.y * (1.0 - wu)
						# Cavalry trampling
						if u.mounted() and not o.mounted() and u.team != o.team and u.vel.length() > 6.0:
							_trample(u, o)
						elif o.mounted() and not u.mounted() and u.team != o.team and o.vel.length() > 6.0:
							_trample(o, u)

func _trample(rider, victim) -> void:
	if victim.get_meta("trampled_until", 0.0) > Time.get_ticks_msec() / 1000.0:
		return
	victim.set_meta("trampled_until", Time.get_ticks_msec() / 1000.0 + 1.0)
	var dir: Vector3 = rider.vel.normalized()
	victim.apply_damage(rider.vel.length() * 2.2, rider, "blunt", dir, 6.0)

func _update_walls() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for w in walls.duplicate():
		if w.until < now:
			walls.erase(w)
			if is_instance_valid(w.node):
				var n: Node3D = w.node
				var tw := n.create_tween()
				tw.tween_property(n, "position:y", n.position.y - 3.0, 0.6)
				tw.tween_callback(n.queue_free)

# ---------------------------------------------------------------------------
# Spatial queries used by units and projectiles
# ---------------------------------------------------------------------------
func resolve_obstacles(p: Vector2, r: float) -> Vector2:
	for o in obstacles:
		var d: Vector2 = p - o.p
		var min_d: float = o.r + r
		var l := d.length()
		if l < min_d and l > 0.0001:
			p = o.p + d / l * min_d
	for w in walls:
		var axis: Vector2 = w.axis
		var normal := Vector2(-axis.y, axis.x)
		var rel: Vector2 = p - w.c
		var a := rel.dot(axis)
		var b := rel.dot(normal)
		var hl: float = w.hl + r
		var ht: float = w.ht + r
		if absf(a) < hl and absf(b) < ht:
			var pen_a := hl - absf(a)
			var pen_b := ht - absf(b)
			if pen_b < pen_a:
				p += normal * signf(b if b != 0.0 else 1.0) * pen_b
			else:
				p += axis * signf(a if a != 0.0 else 1.0) * pen_a
	return p

func point_in_wall(p: Vector3) -> bool:
	for w in walls:
		var axis: Vector2 = w.axis
		var normal := Vector2(-axis.y, axis.x)
		var rel: Vector2 = Vector2(p.x, p.z) - w.c
		if absf(rel.dot(axis)) < w.hl and absf(rel.dot(normal)) < w.ht:
			if p.y < ground_height(w.c.x, w.c.y) + w.h:
				return true
	return false

func unit_hit_by_point(p: Vector3, r: float, team: int, exclude: Array):
	for t in 2:
		if t == team:
			continue
		for u in team_units[t]:
			if exclude.has(u):
				continue
			var d := Vector2(u.position.x - p.x, u.position.z - p.z).length()
			if d < r + u.radius:
				var bottom: float = u.position.y + 0.05
				var top: float = u.position.y + 1.95 + float(u.parts.seat)
				if p.y > bottom and p.y < top:
					return u
	return null

func find_target(u):
	var best = null
	var bd := INF
	var enemies: Array = team_units[1 - u.team]
	for e in enemies:
		var d: float = Vector2(e.position.x - u.position.x, e.position.z - u.position.z).length()
		d += e.engaged_by * 1.5
		if e.is_player:
			d -= 2.0
		if d < bd:
			bd = d
			best = e
	if u.target != null and is_instance_valid(u.target):
		u.target.engaged_by = maxi(0, u.target.engaged_by - 1)
	if best != null:
		best.engaged_by += 1
	return best

func hurt_ally_near(u, r: float):
	for a in team_units[u.team]:
		if a.hp < a.max_hp * 0.6 and u.dist_to(a) < r:
			return a
	return null

func enemies_near(u, r: float) -> int:
	var c := 0
	for e in team_units[1 - u.team]:
		if u.dist_to(e) < r:
			c += 1
	return c

func lead_point(shooter, target, proj_speed: float) -> Vector3:
	var p: Vector3 = target.chest()
	var t: float = shooter.chest().distance_to(p) / maxf(1.0, proj_speed)
	return p + Vector3(target.vel.x, 0, target.vel.z) * t

func path_point(from: Vector3, to: Vector3) -> Vector3:
	if siege == "":
		return to
	var sf := signf(from.z - wall_z)
	var st := signf(to.z - wall_z)
	if sf == st or sf == 0.0:
		return to
	if absf(from.x) < breach_half - 1.0 and absf(from.z - wall_z) < 3.5:
		return to
	return Vector3(clampf(from.x, -breach_half + 1.5, breach_half - 1.5), 0, wall_z + sf * 2.5)

# ---------------------------------------------------------------------------
# Combat resolution
# ---------------------------------------------------------------------------
func on_attack_started(att, windup: float) -> void:
	var victim = att.target
	if att.is_player:
		victim = _nearest_in_front(att, att.melee_reach() + 1.5, 70.0)
	if victim != null and is_instance_valid(victim) and victim.alive:
		victim.incoming_attack(att, windup)

func _nearest_in_front(att, reach: float, half_angle_deg: float):
	var best = null
	var bd := INF
	var fwd: Vector3 = att.forward()
	for e in team_units[1 - att.team]:
		var d3: Vector3 = e.position - att.position
		d3.y = 0
		var d := d3.length()
		if d > reach + e.radius:
			continue
		if d > 0.01 and rad_to_deg(fwd.angle_to(d3 / d)) > half_angle_deg:
			continue
		if d < bd:
			bd = d
			best = e
	return best

func melee_strike(att) -> void:
	if not att.alive:
		return
	var half_angle := 30.0 if att.attack_dir == "thrust" else 60.0
	var victim = _nearest_in_front(att, att.melee_reach(), half_angle)
	if victim == null:
		return
	var w: Dictionary = att.weapon
	var dmg: float = float(w.get("dmg", 8)) * att.dmg_mult * randf_range(0.9, 1.1)
	if att.attack_dir == "overhead":
		dmg *= 1.1
	if att.mounted():
		dmg += Vector2(att.vel.x, att.vel.z).length() * 1.4
	victim.gore_hint = "blade" if w.get("dtype", "cut") == "cut" else ""
	var landed: bool = victim.receive_melee(att, dmg, w.get("dtype", "cut"), att.attack_dir)
	if landed:
		spawn_spark(victim.chest(), Color(0.7, 0.1, 0.1))
		if att.is_player:
			hud_note("Hit %s for %d" % [victim.display_name, int(maxf(dmg * 0.25, dmg - victim.armor * 0.42))])

func spawn_projectile(p: Dictionary, from: Vector3) -> void:
	var pr = Projectile.new()
	p.battle = self
	add_child(pr)
	pr.position = from
	pr.setup(p)

func projectile_hit(pr, u) -> void:
	var from_dir: Vector3 = -pr.vel.normalized()
	from_dir.y = 0
	if u.shield and not u.mounted() and u.forward().dot(from_dir.normalized()) > 0.4 and randf() < 0.75 and pr.fx in ["arrow", "knife", "boomerang"]:
		Sfx.play_at("block", u.position, -8.0)
		return
	var push: Vector3 = pr.vel.normalized()
	push.y = 0
	u.gore_hint = {"water": "water_slice", "ice": "water_slice", "fire": "fire", "blue_fire": "fire",
		"rock": "impale" if pr.radius >= 0.9 else ""}.get(pr.fx, "")
	# a strong gust throws people into the air
	if pr.fx == "air" and pr.knock >= 12.0 and not u.mounted() and not u.airborne:
		u.airborne = true
		u.y_vel = 7.0 + pr.knock * 0.25
	u.apply_damage(pr.dmg, pr.owner_unit, pr.dtype, push.normalized(), pr.knock)
	_apply_effect(u, pr.effect, pr.dmg)
	if is_instance_valid(pr.owner_unit) and pr.owner_unit.is_player:
		hud_note("Hit %s" % u.display_name)

## Status effects from bending: burn, slow, blind, and the expansions'
## freeze (held in ice), root (held by stone or vine).
func _apply_effect(u, effect: String, dmg: float) -> void:
	if not u.alive:
		return
	match effect:
		"burn":
			u.burn_t = 2.0
			u.burn_dps = dmg * 0.12
		"slow":
			u.slow_t = 2.5
		"blind":
			u.blind_t = 3.0
		"freeze":
			u.slow_t = 3.0
			if not u.mounted():
				u._set_action("stagger", 2.2)
			spawn_burst(u.chest(), Color(0.75, 0.9, 1.0), 0.9)
		"root":
			u.root_t = 3.0

func execute_bending(caster, a: Dictionary, point: Vector3) -> void:
	var mult: float = caster.bend_power * caster.bend_mult() * float(caster.buff_val("power", 1.0))
	if caster.is_player:
		mult *= 1.0 + caster.bend_skill * 0.05
	var dmg: float = a.get("dmg", 0.0) * mult
	var fwd: Vector3 = caster.forward()
	var from: Vector3 = caster.chest() + fwd * 0.7
	Sfx.play_at(a.get("sfx", "air"), caster.position, -3.0)
	match a.kind:
		"projectile":
			var dir := (point - from).normalized()
			if dir.length() < 0.5:
				dir = fwd
			var spd: float = a.speed
			var grav: float = a.get("gravity", 0.0)
			if grav > 0.0:
				var t := from.distance_to(point) / spd
				dir.y += grav * t * 0.5 / spd
				dir = dir.normalized()
			spawn_projectile({"owner_unit": caster, "team": caster.team, "vel": dir * spd, "gravity": grav,
				"dmg": dmg, "dtype": "blunt" if a.fx in ["rock", "air", "water"] else "fire", "radius": a.radius,
				"knock": a.knock, "effect": a.get("effect", ""), "fx": a.fx, "life": a.range / spd + 0.3,
				"pierce": a.get("pierce", false)}, from)
		"volley":
			var base := (point - from).normalized()
			for i in a.count:
				var ang := deg_to_rad(lerpf(-a.spread, a.spread, float(i) / maxf(1.0, a.count - 1)))
				var d := base.rotated(Vector3.UP, ang)
				spawn_projectile({"owner_unit": caster, "team": caster.team, "vel": d * a.speed, "gravity": 0.0,
					"dmg": dmg, "dtype": "pierce", "radius": a.radius, "knock": a.knock, "effect": a.get("effect", ""),
					"fx": a.fx, "life": a.range / a.speed}, from)
		"cone":
			for e in team_units[1 - caster.team].duplicate():
				var d3: Vector3 = e.position - caster.position
				d3.y = 0
				if d3.length() < a.range + e.radius and d3.length() > 0.01 and rad_to_deg(fwd.angle_to(d3.normalized())) < a.angle:
					e.gore_hint = {"fire": "fire", "blue_fire": "fire", "water": "water_slice"}.get(a.fx, "")
					if a.get("breath", false):
						e.burn_t = maxf(e.burn_t, 4.0)
						e.burn_dps = maxf(e.burn_dps, 6.0)
					e.apply_damage(dmg, caster, "fire" if a.fx in ["fire", "blue_fire"] else "blunt", d3.normalized(), a.knock)
					_apply_effect(e, a.get("effect", ""), dmg * 0.85)
					if a.fx == "water":
						e.wet_t = 20.0
			_cone_fx(caster, a)
			_field_cone(caster, a)
		"wall":
			var center: Vector3 = caster.position + fwd * a.dist
			var axis := Vector2(fwd.z, -fwd.x).normalized()
			var gh := ground_height(center.x, center.z)
			var col := Color(0.45, 0.36, 0.25) if a.fx == "rock" else Color(0.85, 0.75, 0.5)
			var node := Dress.earth_wall(a.width, a.height, col)
			node.position = Vector3(center.x, gh - a.height, center.z)
			node.rotation.y = caster.facing
			add_child(node)
			var tw := node.create_tween()
			tw.tween_property(node, "position:y", gh + a.height / 2.0 - 0.2, 0.25)
			# stone walls stand for the rest of the battle; sand and ice give way
			var lasting: bool = a.fx == "rock"
			var rec := {"c": Vector2(center.x, center.z), "axis": axis, "hl": a.width / 2.0, "ht": 0.4, "h": a.height,
				"until": INF if lasting else Time.get_ticks_msec() / 1000.0 + a.life, "node": node}
			walls.append(rec)
			if lasting and field != null:
				field.add_structure(rec)
			if a.fx == "ice" and field != null:
				field.soak(center, a.width * 0.5, 25.0)
			# shove anyone standing there
			for t in 2:
				for u in team_units[t]:
					if Vector2(u.position.x - center.x, u.position.z - center.z).length() < a.width / 2.0:
						u.knock += fwd * 5.0
			spawn_burst(center, col, 1.5)
		"heal":
			var healed := 0
			for ally in team_units[caster.team]:
				if ally.dist_to(caster) < a.range:
					if a.amount > 0.0:
						ally.heal(ally.max_hp * a.amount * (1.0 if ally == caster else 0.7))
					if a.get("cure", false):
						ally.burn_t = 0.0
						ally.slow_t = 0.0
						ally.root_t = 0.0
						ally.blind_t = 0.0
					spawn_burst(ally.chest(), Color(0.4, 0.75, 1.0) if a.amount > 0.0 else Color(0.9, 0.92, 0.85), 0.8)
					healed += 1
			if field != null:
				if a.fx == "air":
					var out: int = field.extinguish(caster.position, a.range)
					if out > 0 and caster.is_player:
						hud_note("The wind blows out %d fires" % out)
				elif a.fx == "water":
					field.soak(caster.position, 2.0, 30.0)
			if caster.is_player:
				hud_note(("Healing water mends %d wounds" if a.amount > 0.0 else "The wind clears %d of your people") % healed)
		"quake":
			for e in team_units[1 - caster.team].duplicate():
				var d4: Vector3 = e.position - caster.position
				d4.y = 0
				if d4.length() < a.range:
					e.gore_hint = "impale" if a.fx == "rock" and randf() < 0.3 else ""
					e.apply_damage(dmg, caster, "blunt", d4.normalized(), a.knock)
					if e.alive and not e.mounted():
						e._set_action("stagger", a.stun)
						if not e.airborne:
							e.airborne = true
							# wind throws people far higher than a shaking ground
							e.y_vel = 12.0 + a.knock * 0.2 if a.fx == "air" else 4.0
			_ring_fx(caster.position, a.range, Bending.fx_color(a.fx))
			if field != null:
				if a.fx == "rock":
					for k in 5:
						var ang := randf() * TAU
						field.leave_rock(caster.position + Vector3(cos(ang), 0, sin(ang)) * randf_range(1.5, a.range), randf_range(0.8, 1.6))
				elif a.fx == "air":
					field.extinguish(caster.position, a.range * 0.6)
		"pillar":
			_raise_pillar(caster, a, point, dmg)
		"buff":
			caster.start_buff(a)
			spawn_burst(caster.chest(), Bending.fx_color(a.fx), 1.2)
			if caster.is_player:
				hud_note("%s (%ds)" % [a.name, int(a.get("dur", 8.0))])
		"dash":
			# Travel along the facing; everyone near the path is struck
			var dir3: Vector3 = point - caster.position
			dir3.y = 0.0
			dir3 = dir3.normalized() if dir3.length() > 0.5 else fwd
			var start: Vector3 = caster.position
			var end3: Vector3 = start + dir3 * float(a.dist)
			var endp := resolve_obstacles(Vector2(end3.x, end3.z), caster.radius)
			end3 = Vector3(endp.x, ground_height(endp.x, endp.y), endp.y)
			for e in team_units[1 - caster.team].duplicate():
				var rel2: Vector3 = e.position - start
				rel2.y = 0.0
				var along2 := rel2.dot(dir3)
				if along2 > 0.0 and along2 < float(a.dist) and (rel2 - dir3 * along2).length() < 1.4:
					e.gore_hint = "fire" if a.fx in ["fire", "blue_fire"] else ""
					e.apply_damage(dmg, caster, "fire" if a.fx == "fire" else "blunt", dir3.rotated(Vector3.UP, PI / 2.0 * signf(randf() - 0.5)), a.knock)
					_apply_effect(e, a.get("effect", ""), dmg)
			spawn_burst(start + Vector3(0, 0.6, 0), Bending.fx_color(a.fx), 1.0)
			if field != null and a.fx == "fire":
				for k in int(float(a.dist) / 2.0):
					field.ignite(start + dir3 * (1.0 + k * 2.0), 0.6, 0.7)
			caster.position = end3
			caster.hold_pos = end3
			spawn_burst(end3 + Vector3(0, 0.6, 0), Bending.fx_color(a.fx), 1.2)
		"nova":
			for e in team_units[1 - caster.team].duplicate():
				var d5: Vector3 = e.position - caster.position
				d5.y = 0
				if d5.length() < a.range:
					var push5: Vector3 = d5.normalized() * (-1.0 if a.get("pull", false) else 1.0)
					e.gore_hint = "fire" if a.fx in ["fire", "blue_fire"] else ""
					e.apply_damage(dmg, caster, "fire" if a.fx == "fire" else "blunt", push5, a.knock)
					_apply_effect(e, a.get("effect", ""), dmg)
			_ring_fx(caster.position, a.range, Bending.fx_color(a.fx))
			spawn_burst(caster.chest(), Bending.fx_color(a.fx), 1.4)
			if field != null:
				for k in 10:
					var ang2 := TAU * k / 10.0
					var rp: Vector3 = caster.position + Vector3(cos(ang2), 0, sin(ang2)) * float(a.range) * 0.85
					if a.fx in ["fire", "blue_fire"]:
						field.ignite(rp, 0.6, 0.9)
					elif a.fx == "water":
						field.soak(rp, 0.8, 30.0)
		"line":
			var dir4: Vector3 = point - caster.position
			dir4.y = 0.0
			dir4 = dir4.normalized() if dir4.length() > 0.5 else fwd
			for e in team_units[1 - caster.team].duplicate():
				var rel4: Vector3 = e.position - caster.position
				rel4.y = 0.0
				var along4 := rel4.dot(dir4)
				if along4 > 0.5 and along4 < float(a.range) and (rel4 - dir4 * along4).length() < float(a.width):
					e.gore_hint = "impale" if randf() < 0.5 else ""
					e.apply_damage(dmg, caster, "blunt", Vector3.UP * 0.2 + dir4, a.knock)
					if e.alive and not e.mounted():
						e._set_action("stagger", a.get("stun", 1.0))
						if not e.airborne:
							e.airborne = true
							e.y_vel = 5.0
			var steps := int(float(a.range) / 2.0)
			for k in steps:
				var pt: Vector3 = caster.position + dir4 * (1.5 + k * 2.0)
				pt.y = ground_height(pt.x, pt.z)
				if field != null:
					field.leave_rock(pt + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6)), randf_range(0.7, 1.3))
				else:
					leave_debris(pt)
				if k % 2 == 0:
					spawn_burst(pt, Bending.fx_color(a.fx), 0.7)
		"lightning":
			var dir2 := (point - from).normalized()
			var hit = null
			var hit_d: float = a.range
			for e in team_units[1 - caster.team]:
				var rel: Vector3 = e.chest() - from
				var along := rel.dot(dir2)
				if along < 0.0 or along > a.range:
					continue
				var perp := (rel - dir2 * along).length()
				if perp < 0.9 and along < hit_d:
					hit_d = along
					hit = e
			var end: Vector3 = from + dir2 * hit_d
			if hit != null:
				var wet_hit: bool = hit.wet_t > 0.0
				hit.apply_damage(dmg * (1.5 if wet_hit else 1.0), caster, "fire", dir2, a.knock)
				# water carries it on to everyone wet and close
				if wet_hit:
					for e2 in team_units[1 - caster.team].duplicate():
						if e2 != hit and e2.alive and e2.wet_t > 0.0 and e2.dist_to(hit) < 4.0:
							e2.apply_damage(dmg * 0.5, caster, "fire", Vector3.ZERO, 1.0)
							_lightning_fx(hit.chest(), e2.chest())
					if caster.is_player:
						hud_note("The lightning runs through the water!")
			elif field != null:
				field.ignite(end, 0.8, 1.0)
			_lightning_fx(from, end)

## Fire cones set the grass alight along their reach, water cones soak it,
## wind fans whatever is already burning.
func _field_cone(caster, a: Dictionary) -> void:
	if field == null:
		return
	var fwd: Vector3 = caster.forward()
	for k in 7:
		var ang := deg_to_rad(randf_range(-a.angle, a.angle) * 0.8)
		var p: Vector3 = caster.position + fwd.rotated(Vector3.UP, ang) * randf_range(1.5, float(a.range))
		match a.fx:
			"fire", "blue_fire": field.ignite(p, 0.6, 0.8)
			"water": field.soak(p, 1.0, 35.0)
	if a.fx == "air":
		field.gust(caster.position, fwd, float(a.range) + 4.0)

## A column of rock driven up under the target point: everyone on it is thrown
## up and hurt, and the column stays as an obstacle for the rest of the battle.
func _raise_pillar(caster, a: Dictionary, point: Vector3, dmg: float) -> void:
	var to: Vector3 = point - caster.position
	to.y = 0.0
	var rng_max: float = a.get("range", 14.0)
	if to.length() > rng_max:
		to = to.normalized() * rng_max
	if to.length() < 2.0:
		to = caster.forward() * 3.0
	var c: Vector3 = caster.position + to
	var gh := ground_height(c.x, c.z)
	var r: float = a.get("radius", 0.9)
	var h: float = a.get("height", 3.0)
	var node := Node3D.new()
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r * 0.85
	cm.bottom_radius = r * 1.1
	cm.height = h
	cm.radial_segments = 7
	cm.rings = 2
	mi.mesh = cm
	var rm: ShaderMaterial = Land.rock_material(biome).duplicate()
	rm.set_shader_parameter("use_vertex_color", false)
	mi.material_override = rm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	node.add_child(mi)
	node.rotation.y = randf() * TAU
	add_child(node)
	node.position = Vector3(c.x, gh - h * 0.5, c.z)
	var tw := node.create_tween()
	tw.tween_property(node, "position:y", gh + h * 0.5 - 0.1, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for t in 2:
		for u in team_units[t].duplicate():
			var d := Vector2(u.position.x - c.x, u.position.z - c.z)
			if d.length() < r + u.radius + 0.3:
				if t != caster.team:
					u.gore_hint = "impale"
					u.apply_damage(dmg, caster, "blunt", Vector3(d.x, 0, d.y).normalized(), a.get("knock", 2.0))
				if u.alive and not u.mounted():
					u.airborne = true
					u.y_vel = float(a.get("launch", 9.0))
					u._set_action("stagger", 1.0)
				u.knock += Vector3(d.x, 0, d.y).normalized() * 3.0
	var rec := {"c": Vector2(c.x, c.z), "axis": Vector2(1, 0), "hl": r, "ht": r, "h": h, "until": INF, "node": node, "pillar": true}
	walls.append(rec)
	if field != null:
		field.add_structure(rec)
	spawn_burst(Vector3(c.x, gh + 0.3, c.z), Bending.fx_color("rock"), 1.6)
	if caster.is_player:
		hud_note("A pillar of stone")

## The oldest structure gives way when the field has too many.
func crumble_structure(rec: Dictionary) -> void:
	walls.erase(rec)
	if is_instance_valid(rec.get("node")):
		var n: Node3D = rec.node
		var tw := n.create_tween()
		tw.tween_property(n, "position:y", n.position.y - float(rec.h) - 0.5, 0.8)
		tw.tween_callback(n.queue_free)

func _cone_fx(caster, a: Dictionary) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 60
	p.lifetime = 0.5
	p.explosiveness = 0.9
	p.direction = Vector3(0, 0, 1)
	p.spread = a.angle * 0.6
	p.initial_velocity_min = a.range * 1.5
	p.initial_velocity_max = a.range * 2.5
	p.gravity = Vector3(0, 1, 0)
	p.damping_min = 4.0
	p.damping_max = 6.0
	var sm := SphereMesh.new()
	sm.radius = 0.25
	sm.height = 0.5
	sm.radial_segments = 6
	sm.rings = 3
	p.mesh = sm
	var c := Bending.fx_color(a.fx)
	p.material_override = MB.mat(c, 0.5, a.fx in ["fire", "blue_fire"])
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = grad
	add_child(p)
	p.global_position = caster.chest()
	p.rotation.y = caster.facing
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)

func _ring_fx(center: Vector3, r: float, c: Color) -> void:
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.3
	tm.outer_radius = 0.8
	ring.mesh = tm
	ring.material_override = MB.mat(c, 0.8)
	add_child(ring)
	ring.position = center + Vector3(0, 0.3, 0)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector3(r, 1, r), 0.4)
	tw.tween_callback(ring.queue_free)
	spawn_burst(center, c, 2.0)

func _lightning_fx(a: Vector3, b: Vector3) -> void:
	var root := Node3D.new()
	add_child(root)
	var pts := [a]
	var segs := 8
	for i in range(1, segs):
		pts.append(a.lerp(b, float(i) / segs) + Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)))
	pts.append(b)
	for i in segs:
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.08, 0.08, p0.distance_to(p1))
		seg.mesh = bm
		seg.material_override = MB.mat(Color(0.75, 0.9, 1.0), 0.2, true)
		root.add_child(seg)
		seg.position = (p0 + p1) / 2.0
		if not p0.is_equal_approx(p1):
			seg.look_at(p1, Vector3.UP if absf((p1 - p0).normalized().y) < 0.99 else Vector3.RIGHT)
	var light := OmniLight3D.new()
	light.light_color = Color(0.7, 0.85, 1.0)
	light.light_energy = 1.2 if GS.settings.get("reduce_flashing", false) else 6.0
	light.omni_range = 20.0
	root.add_child(light)
	light.position = b
	get_tree().create_timer(0.18).timeout.connect(root.queue_free)

func spawn_burst(pos: Vector3, c: Color, size: float = 1.0) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 16
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 2.0 * size
	p.initial_velocity_max = 5.0 * size
	p.gravity = Vector3(0, -6, 0)
	var sm := SphereMesh.new()
	sm.radius = 0.12 * size
	sm.height = 0.24 * size
	sm.radial_segments = 6
	sm.rings = 3
	p.mesh = sm
	p.material_override = MB.mat(Color(c, 1.0), 0.6, true)
	add_child(p)
	p.global_position = pos
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

func spawn_spark(pos: Vector3, c: Color = Color(1, 0.9, 0.5)) -> void:
	spawn_burst(pos, c, 0.4)

func leave_debris(pos: Vector3) -> void:
	var r := MB.sphere(0.35, Color(0.45, 0.36, 0.25), Vector3(pos.x, ground_height(pos.x, pos.z) + 0.1, pos.z))
	r.scale = Vector3(1, 0.6, 1)
	add_child(r)
	get_tree().create_timer(20.0).timeout.connect(r.queue_free)

# ---------------------------------------------------------------------------
# Casualties and battle end
# ---------------------------------------------------------------------------
func on_unit_down(u, killer, dtype: String) -> void:
	team_units[u.team].erase(u)
	var kname: String = killer.display_name if killer != null and is_instance_valid(killer) else "fire"
	var wounded := false
	if u.is_player:
		player_downed = true
		player_controlled = false
		if (arena >= 0 or duel != "") and not battle_over:
			battle_over = true
			winner = 1
			big_label.text = "DEFEAT\nPress Tab to continue"
			return
		spectate_target = null
		feed_msg("You have been knocked unconscious! (Tab: fast-forward the battle)", Color(1, 0.4, 0.3))
	elif u.companion_id != "":
		companions_down.append(u.companion_id)
		feed_msg("%s has been knocked out by %s." % [u.display_name, kname], Color(1, 0.6, 0.4))
	elif u.lord_id != "":
		feed_msg("%s has been defeated!" % u.display_name, Color(1, 0.85, 0.4))
	elif u.troop_id == "avatar":
		# The Avatar is beaten, never killed: their companions carry them off
		if autotest:
			print("AVATAR DOWN after %.1fs, casts by element: %s" % [_autotest_t, u.get_meta("casts", {})])
		feed_msg("%s falls, and is carried from the field by their companions." % u.display_name, Color(0.85, 0.95, 1))
	else:
		var chance := 0.5 if u.team == 0 else 0.4
		if dtype == "blunt":
			chance = 0.9
		# Pemba never takes a life: their blows only knock people down
		if killer != null and is_instance_valid(killer) and killer.companion_id != "" and Data.companions.get(killer.companion_id, {}).get("nonlethal", false):
			chance = 1.0
		wounded = randf() < chance and not u.has_meta("gored")
		if not casualties.has(u.party_key):
			casualties[u.party_key] = {}
		var c: Dictionary = casualties[u.party_key]
		if not c.has(u.troop_id):
			c[u.troop_id] = {"killed": 0, "wounded": 0}
		c[u.troop_id]["wounded" if wounded else "killed"] += 1
		if killer != null and is_instance_valid(killer) and (killer.is_player or u.team == 0 or killer.is_hero):
			feed_msg("%s %s %s." % [kname, "knocked out" if wounded else "killed", u.display_name],
				Color(0.7, 1, 0.7) if u.team == 1 else Color(1, 0.7, 0.6))
	if killer != null and is_instance_valid(killer) and killer.is_player:
		player_kills += 1
	_check_end()

func _check_end() -> void:
	if battle_over:
		return
	var a0: int = team_units[0].size() + reserves[0].size()
	var a1: int = team_units[1].size() + reserves[1].size()
	if a1 == 0:
		battle_over = true
		winner = 0
		big_label.text = "VICTORY!\nPress Tab to leave the field"
		Sfx.play("horn", -4.0)
	elif a0 == 0:
		battle_over = true
		winner = 1
		big_label.text = "DEFEAT\nPress Tab to continue"
	if battle_over:
		Engine.time_scale = 1.0 if not autotest else Engine.time_scale

func _finish(retreat: bool) -> void:
	if _finished:
		return
	_finished = true
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if player_unit != null and player_unit.alive:
		GS.player.hp = int(maxf(1.0, player_unit.hp))
	if autotest:
		print("avg physics frame: %.2f ms over %d frames, units %d" % [_prof_us / 1000.0 / maxf(1, _prof_n), _prof_n, units.size()])
		print("BATTLE RESULT winner=", winner, " casualties=", casualties, " player_downed=", player_downed)
	if duel != "":
		GS.finish_duel(winner == 0 and not retreat, duel, player_unit.hp if player_unit != null else 1.0)
	elif arena >= 0:
		GS.finish_arena(winner == 0 and not retreat, arena, player_unit.hp if player_unit != null else 1.0)
	elif retreat:
		GS.retreat_battle(casualties, companions_down)
	else:
		GS.finish_battle(winner == 0, casualties, player_downed, companions_down)
	if autotest and not autotest_return:
		get_tree().quit()
		return
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")

# ---------------------------------------------------------------------------
# Player input & camera
# ---------------------------------------------------------------------------
func player_move_vector() -> Vector3:
	var v := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		v.z += 1
	if Input.is_action_pressed("move_back"):
		v.z -= 1
	if Input.is_action_pressed("move_left"):
		v.x += 1
	if Input.is_action_pressed("move_right"):
		v.x -= 1
	if v == Vector3.ZERO:
		return v
	v = v.normalized().rotated(Vector3.UP, cam_yaw)
	if Input.is_action_pressed("walk"):
		v *= 0.5
	return v

func aim_point() -> Vector3:
	var vp := get_viewport().get_visible_rect().size
	var center := vp / 2.0
	var from := cam.project_ray_origin(center)
	var dir := cam.project_ray_normal(center)
	# Units first
	var best_t := INF
	for t in 2:
		for u in team_units[t]:
			if u == player_unit:
				continue
			var c: Vector3 = u.chest() - Vector3(0, 0.3, 0)
			var rel := c - from
			var along := rel.dot(dir)
			if along < 1.0 or along > 120.0:
				continue
			if (rel - dir * along).length() < 0.7 and along < best_t:
				best_t = along
	if best_t < INF:
		return from + dir * best_t
	var p := from
	for i in 240:
		p += dir * 0.5
		if p.y <= ground_height(p.x, p.z) or point_in_wall(p):
			return p
	return from + dir * 120.0

func _mouse_dir() -> String:
	var m := mouse_accum
	if m.length() < 2.0:
		return ["left", "right", "overhead", "thrust"].pick_random() if not GS.settings.auto_block else "right"
	if absf(m.x) > absf(m.y):
		return "right" if m.x > 0 else "left"
	return "overhead" if m.y < 0 else "thrust"

func _unhandled_input(event: InputEvent) -> void:
	if autotest:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.physical_keycode == KEY_ESCAPE:
			_toggle_pause()
			return
		if paused:
			return
		match k.physical_keycode:
			KEY_TAB:
				if battle_over:
					_finish(false)
				elif player_downed:
					Engine.time_scale = 4.0 if Engine.time_scale < 2.0 else 1.0
			KEY_V:
				cam_far = not cam_far
			KEY_F1:
				_order("hold")
			KEY_F2:
				_order("follow")
			KEY_F3:
				_order("charge")
	if paused or player_unit == null or not player_controlled or not player_unit.alive:
		if event is InputEventMouseMotion and not paused:
			cam_yaw -= event.relative.x * GS.settings.mouse_sens * 0.01
		return
	var pu = player_unit
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var sens: float = GS.settings.mouse_sens * 0.01
		cam_yaw -= mm.relative.x * sens
		var dy := mm.relative.y * sens * (-1.0 if GS.settings.invert_y else 1.0)
		cam_pitch = clampf(cam_pitch - dy, -1.1, 0.7)
		mouse_accum += mm.relative
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if player_ranged_mode:
					if not pu.start_aim():
						hud_note("Out of ammunition!" if pu.ammo <= 0 else "")
				else:
					pu.start_attack(_mouse_dir())
			else:
				if player_ranged_mode:
					pu.release_aim(aim_point())
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				pu.start_block(_mouse_dir())
			else:
				pu.stop_block()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			cam_dist = maxf(1.0, cam_dist - 0.5)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			cam_dist = minf(12.0, cam_dist + 0.5)
	elif event is InputEventKey and event.pressed and not event.echo:
		var k2 := event as InputEventKey
		match k2.physical_keycode:
			KEY_SPACE:
				pu.jump()
			KEY_1:
				player_ranged_mode = false
			KEY_2:
				if pu.ranged_id != "":
					player_ranged_mode = true
				else:
					hud_note("You have no ranged weapon.")
			KEY_Q:
				_player_cast("q")
			KEY_E:
				_player_cast("e")
			KEY_R:
				_player_cast("r")
			KEY_F:
				_player_form()

## F: the player's own bending form (Character -> Bending Forms).
func _player_form() -> void:
	var pu = player_unit
	var forms: Array = GS.player.get("forms", [])
	var idx: int = int(GS.player.get("form_f", -1))
	if pu.bend == "":
		hud_note("You are not a bender.")
		return
	if idx < 0 or idx >= forms.size():
		hud_note("No form is set on F. Design one under Character -> Bending Forms.")
		return
	var msg: String = pu.cast_form(forms[idx])
	if msg != "" and msg != "busy":
		hud_note(msg)

func _player_cast(slot: String) -> void:
	var pu = player_unit
	if pu.bend == "":
		hud_note("You are not a bender.")
		return
	var a: Dictionary = pu.ability_for(slot)
	if a.is_empty():
		return
	if pu.bend_block_t > 0.0:
		hud_note("Your chi is blocked!")
		return
	if pu.bend_mult() <= 0.01:
		hud_note("The eclipse has taken your bending!")
		return
	if a.get("min_skill", 0) > pu.bend_skill:
		hud_note("%s requires Bending skill %d." % [a.name, a.min_skill])
		return
	if pu.chi < a.cost:
		hud_note("Not enough chi.")
		return
	if pu.cooldowns.get(slot, 0.0) > 0.0:
		hud_note("%s is not ready (%.1fs)." % [a.name, pu.cooldowns[slot]])
		return
	match pu.action:
		"stagger":
			hud_note("Staggered — you can't bend until you recover.")
			return
		"windup", "aim":
			hud_note("Finish your attack first.")
			return
	pu.cast(slot, aim_point())

func _order(o: String) -> void:
	var i := 0
	for u in team_units[0]:
		if u.is_player:
			continue
		u.order = o
		var row := int(i / 12)
		var col := i % 12
		var fwd := Vector3(sin(cam_yaw), 0, cos(cam_yaw))
		var right := Vector3(-fwd.z, 0, fwd.x)
		u.formation_offset = right * (col - 5.5) * 1.6 - fwd * (2.5 + row * 1.8)
		if o == "hold" and player_unit != null:
			u.hold_pos = player_unit.position + u.formation_offset
		i += 1
	var names := {"hold": "Hold this position!", "follow": "Follow me!", "charge": "Charge!"}
	feed_msg("You order: " + names[o], Color(0.9, 0.9, 1))
	Sfx.play("horn", -14.0, 1.4)

func _update_camera(delta: float) -> void:
	var focus = player_unit
	if focus == null or not focus.alive:
		if spectate_target == null or not is_instance_valid(spectate_target) or not spectate_target.alive:
			spectate_target = team_units[0][0] if not team_units[0].is_empty() else (team_units[1][0] if not team_units[1].is_empty() else null)
		focus = spectate_target
	if focus == null:
		return
	var dist := cam_dist * (1.8 if cam_far else 1.0)
	if focus.mounted():
		dist *= 1.3
	var head: Vector3 = focus.position + Vector3(0, 1.7 + float(focus.parts.seat), 0)
	var fwd := Vector3(sin(cam_yaw), 0, cos(cam_yaw))
	var right := Vector3(-fwd.z, 0, fwd.x)
	var back := -fwd * cos(cam_pitch) * dist + Vector3(0, -sin(cam_pitch) * dist, 0)
	var target_pos := head + back + right * 0.6
	var gh := ground_height(target_pos.x, target_pos.z) + 0.4
	target_pos.y = maxf(target_pos.y, gh)
	cam.position = cam.position.lerp(target_pos, minf(1.0, delta * 20.0)) if cam.position != Vector3.ZERO else target_pos
	var look := head + fwd * 6.0 + Vector3(0, sin(cam_pitch) * 6.0, 0) + right * 0.6
	if not look.is_equal_approx(cam.position):
		cam.look_at(look, Vector3.UP)

func _toggle_pause() -> void:
	paused = not paused
	pause_panel.visible = paused
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	if paused:
		_build_pause_menu()

# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------
func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.theme()
	hud.add_child(root)
	crosshair = Control.new()
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.draw.connect(func():
		var c := crosshair.size / 2.0
		var col := Color(1, 1, 1, 0.8)
		crosshair.draw_line(c - Vector2(9, 0), c - Vector2(3, 0), col, 2.0)
		crosshair.draw_line(c + Vector2(3, 0), c + Vector2(9, 0), col, 2.0)
		crosshair.draw_line(c - Vector2(0, 9), c - Vector2(0, 3), col, 2.0)
		crosshair.draw_line(c + Vector2(0, 3), c + Vector2(0, 9), col, 2.0))
	root.add_child(crosshair)
	var bl := PanelContainer.new()
	bl.anchor_top = 1.0
	bl.anchor_bottom = 1.0
	bl.offset_left = 12
	bl.offset_top = -128
	bl.offset_right = 430
	bl.offset_bottom = -12
	# grow up from the bottom edge as the larger text needs more room
	bl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(bl)
	var v := UI.vbox(4)
	bl.add_child(v)
	hp_bar = UI.bar(100, 100, Color(0.75, 0.15, 0.1), 380, 16)
	v.add_child(hp_bar)
	chi_bar = UI.bar(100, 100, Color(0.2, 0.55, 0.95), 380, 12)
	v.add_child(chi_bar)
	mount_bar = UI.bar(100, 100, Color(0.6, 0.45, 0.25), 380, 10)
	v.add_child(mount_bar)
	info_label = UI.label("", 14)
	v.add_child(info_label)
	var br := PanelContainer.new()
	br.anchor_left = 1.0
	br.anchor_right = 1.0
	br.anchor_top = 1.0
	br.anchor_bottom = 1.0
	br.offset_left = -360
	br.offset_top = -100
	br.offset_right = -12
	br.offset_bottom = -12
	br.grow_vertical = Control.GROW_DIRECTION_BEGIN
	br.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.add_child(br)
	count_label = UI.label("", 15)
	br.add_child(count_label)
	feed = UI.vbox(2)
	feed.position = Vector2(14, 12)
	feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(feed)
	big_label = UI.label("", 40, Color(1, 0.92, 0.6))
	big_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0))
	big_label.add_theme_constant_override("outline_size", 8)
	big_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	big_label.offset_top = 120
	big_label.offset_left = -400
	big_label.offset_right = 400
	root.add_child(big_label)
	note_label = UI.label("", 20, Color(1, 1, 1))
	note_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	note_label.add_theme_constant_override("outline_size", 6)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.set_anchors_preset(Control.PRESET_CENTER)
	note_label.offset_top = 40
	note_label.offset_left = -300
	note_label.offset_right = 300
	root.add_child(note_label)
	pause_panel = Control.new()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.visible = false
	root.add_child(pause_panel)

func _build_pause_menu() -> void:
	UI.clear(pause_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(cc)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(560, 420)
	cc.add_child(p)
	var v := UI.vbox(8)
	p.add_child(v)
	v.add_child(UI.title("Battle Paused"))
	v.add_child(UI.rich("[b]Controls[/b]\nWASD move · Mouse look · LMB attack (direction follows your last mouse movement) · RMB block · Space jump · Shift walk\n1 melee · 2 ranged (hold LMB to draw, release to shoot)\nQ / E / R bending abilities · V camera distance\nF1 hold position · F2 follow me · F3 charge · Tab leave when the battle is over", 520))
	v.add_child(UI.option("Resume", _toggle_pause))
	v.add_child(UI.option("Settings", func():
		var sw = SettingsWindow.new()
		pause_panel.add_child(sw)))
	if not battle_over:
		v.add_child(UI.option("Retreat from the battle (your fallen stay fallen)", func():
			paused = false
			_finish(true)))
	else:
		v.add_child(UI.option("Leave the battlefield", func():
			paused = false
			_finish(false)))

func feed_msg(text: String, c: Color = Color(1, 1, 1)) -> void:
	if feed == null:
		return
	var l := UI.label(text, 15, c)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	feed.add_child(l)
	while feed.get_child_count() > 7:
		var o := feed.get_child(0)
		feed.remove_child(o)
		o.queue_free()
	var tw := l.create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(l, "modulate:a", 0.0, 1.0)
	tw.tween_callback(func():
		if is_instance_valid(l):
			l.queue_free())

func hud_note(text: String) -> void:
	if note_label == null or text == "":
		return
	note_label.text = text
	_note_t = 1.5

func _update_hud(delta: float) -> void:
	_note_t -= delta
	if _note_t <= 0.0 and note_label:
		note_label.text = ""
	var pu = player_unit
	if pu != null:
		hp_bar.max_value = pu.max_hp
		hp_bar.value = maxf(0.0, pu.hp)
		chi_bar.visible = pu.bend != ""
		chi_bar.max_value = pu.max_chi
		chi_bar.value = pu.chi
		mount_bar.visible = pu.mount_id != ""
		mount_bar.max_value = maxf(1.0, pu.mount_max)
		mount_bar.value = maxf(0.0, pu.mount_hp)
		var txt := "HP %d/%d" % [int(maxf(0, pu.hp)), int(pu.max_hp)]
		txt += "   Weapon: %s" % (Data.item(pu.ranged_id).name + " (%d)" % pu.ammo if player_ranged_mode else Data.item(pu.weapon_id).name)
		if pu.bend != "":
			var parts := []
			for slot in ["q", "e", "r"]:
				var a: Dictionary = pu.ability_for(slot)
				if a.is_empty():
					continue
				var st := "ready"
				if a.get("min_skill", 0) > pu.bend_skill:
					st = "locked"
				elif pu.cooldowns.get(slot, 0.0) > 0.0:
					st = "%.1fs" % pu.cooldowns[slot]
				elif pu.chi < a.cost:
					st = "chi"
				parts.append("%s %s [%s]" % [slot.to_upper(), a.name, st])
			var fi: int = int(GS.player.get("form_f", -1))
			var fl: Array = GS.player.get("forms", [])
			if fi >= 0 and fi < fl.size():
				var fst := "ready" if pu.cooldowns.get("f", 0.0) <= 0.0 else "%.1fs" % pu.cooldowns.f
				parts.append("F %s [%s]" % [fl[fi].name, fst])
			txt += "\n" + "   ".join(parts)
		info_label.text = txt
		crosshair.visible = pu.alive and not paused
	var a0: int = team_units[0].size()
	var a1: int = team_units[1].size()
	count_label.text = "Your side: %d  (+%d reserves)\nEnemy: %d  (+%d reserves)\nF1 Hold · F2 Follow · F3 Charge · Esc menu" % [a0, reserves[0].size(), a1, reserves[1].size()]
