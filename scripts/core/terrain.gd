extends RefCounted
## World terrain: land, heights, biomes, forests and rivers, baked by
## tools/make_world.py into assets/world/ and sampled on a grid of 2 map units,
## so the simulation and the map renderer agree.

const CELL := 2.0
const GW := 801   # MAP_W / CELL + 1
const GH := 601   # MAP_H / CELL + 1
const HEIGHT_FILE := "res://assets/world/height.bin"
const INFO_FILE := "res://assets/world/info.bin"

static var _land: PackedFloat32Array
static var _height: PackedFloat32Array
static var _biome: PackedByteArray
static var _info: PackedByteArray
static var _ready := false

const BIOMES := ["ocean", "grass", "forest", "mountain", "snow", "desert", "swamp", "volcanic", "highland", "beach"]
const BIOME_SPEED := {
	"ocean": 0.7, "grass": 1.0, "forest": 0.82, "mountain": 0.62, "snow": 0.8,
	"desert": 0.75, "swamp": 0.6, "volcanic": 0.9, "highland": 0.85, "beach": 0.95,
}
const BIOME_COLOR := {
	"ocean": Color(0.1, 0.3, 0.5), "grass": Color(0.42, 0.58, 0.28), "forest": Color(0.22, 0.42, 0.2),
	"mountain": Color(0.5, 0.46, 0.4), "snow": Color(0.92, 0.95, 0.98), "desert": Color(0.86, 0.76, 0.52),
	"swamp": Color(0.3, 0.38, 0.24), "volcanic": Color(0.38, 0.3, 0.27), "highland": Color(0.5, 0.55, 0.38),
	"beach": Color(0.85, 0.8, 0.6),
}

static func ensure() -> void:
	if _ready:
		return
	_ready = true
	_height = FileAccess.get_file_as_bytes(HEIGHT_FILE).to_float32_array()
	_info = FileAccess.get_file_as_bytes(INFO_FILE)
	var n := GW * GH
	_land.resize(n)
	_biome.resize(n)
	for i in n:
		_biome[i] = _info[i * 4]
		# coast distance: 128 at the shore, 4 per map unit
		_land[i] = (float(_info[i * 4 + 1]) - 128.0) / 4.0

## The baked grids as textures for the map shaders: heights (RF) and
## biome / coast / forest / river (RGBA8).
static func height_texture() -> ImageTexture:
	ensure()
	var img := Image.create_from_data(GW, GH, false, Image.FORMAT_RF, _height.to_byte_array())
	return ImageTexture.create_from_image(img)

static func info_texture() -> ImageTexture:
	ensure()
	var img := Image.create_from_data(GW, GH, false, Image.FORMAT_RGBA8, _info)
	return ImageTexture.create_from_image(img)

## River strength at a point (0..1).
static func river(p: Vector2) -> float:
	ensure()
	return float(_info[_idx(p) * 4 + 3]) / 255.0

## Forest density at a point (0..1).
static func forest(p: Vector2) -> float:
	ensure()
	return float(_info[_idx(p) * 4 + 2]) / 255.0

static func _idx(p: Vector2) -> int:
	var gx := clampi(int(round(p.x / CELL)), 0, GW - 1)
	var gy := clampi(int(round(p.y / CELL)), 0, GH - 1)
	return gy * GW + gx

static func _bilinear(arr: PackedFloat32Array, p: Vector2) -> float:
	var fx := clampf(p.x / CELL, 0.0, GW - 1.001)
	var fy := clampf(p.y / CELL, 0.0, GH - 1.001)
	var x0 := int(fx)
	var y0 := int(fy)
	var tx := fx - x0
	var ty := fy - y0
	var a := arr[y0 * GW + x0]
	var b := arr[y0 * GW + x0 + 1]
	var c := arr[(y0 + 1) * GW + x0]
	var d := arr[(y0 + 1) * GW + x0 + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)

static func land_value(p: Vector2) -> float:
	ensure()
	return _bilinear(_land, p)

static func is_land(p: Vector2) -> bool:
	return land_value(p) > 0.0

static func height(p: Vector2) -> float:
	ensure()
	return _bilinear(_height, p)

static func biome(p: Vector2) -> String:
	ensure()
	return BIOMES[_biome[_idx(p)]]

static func speed_mult(p: Vector2) -> float:
	return BIOME_SPEED.get(biome(p), 1.0)

static func grid_height(gx: int, gy: int) -> float:
	ensure()
	return _height[gy * GW + gx]

static func grid_biome(gx: int, gy: int) -> String:
	ensure()
	return BIOMES[_biome[gy * GW + gx]]

## Height used to place things on the map (never below the water surface).
static func surface(p: Vector2) -> float:
	return maxf(0.0, height(p))

## Random land point within radius of a center (falls back to center).
static func random_land_near(center: Vector2, radius: float) -> Vector2:
	for i in 20:
		var p := center + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
		p.x = clampf(p.x, 10.0, Data.MAP_W - 10.0)
		p.y = clampf(p.y, 10.0, Data.MAP_H - 10.0)
		if is_land(p):
			return p
	return center
