extends RefCounted
## World terrain: land mask, heights and biomes, sampled on a cached grid so
## both the simulation and the map renderer agree.

const CELL := 8.0
const GW := 201   # MAP_W / CELL + 1
const GH := 151   # MAP_H / CELL + 1

static var _land: PackedFloat32Array
static var _height: PackedFloat32Array
static var _biome: PackedByteArray
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
	var n := FastNoiseLite.new()
	n.seed = 1337
	n.frequency = 0.012
	n.fractal_octaves = 4
	var mtn := FastNoiseLite.new()
	mtn.seed = 4242
	mtn.frequency = 0.006
	mtn.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	mtn.fractal_octaves = 3
	var forest := FastNoiseLite.new()
	forest.seed = 99
	forest.frequency = 0.02
	_land.resize(GW * GH)
	_height.resize(GW * GH)
	_biome.resize(GW * GH)
	var ell: Array = Data.land_ellipses
	var regions: Array = Data.biome_regions
	for gy in GH:
		for gx in GW:
			var p := Vector2(gx * CELL, gy * CELL)
			var best := -2.0
			for e in ell:
				var d := Vector2(p.x - e[0], p.y - e[1]).rotated(-deg_to_rad(e[4]))
				var v: float = 1.0 - sqrt(pow(d.x / e[2], 2) + pow(d.y / e[3], 2))
				if v > best:
					best = v
			best += n.get_noise_2d(p.x, p.y) * 0.22
			if p.y < 45.0:
				best = maxf(best, (45.0 - p.y) / 45.0)
			if p.y > Data.MAP_H - 45.0:
				best = maxf(best, (p.y - (Data.MAP_H - 45.0)) / 45.0)
			var i := gy * GW + gx
			_land[i] = best
			var h := 0.0
			if best <= 0.0:
				h = maxf(-6.0, best * 20.0) - 0.5
			else:
				var ridge := clampf((mtn.get_noise_2d(p.x, p.y) - 0.42) * 3.0, 0.0, 1.0)
				h = 0.6 + minf(best, 0.4) * 6.0 + ridge * 16.0 * smoothstep(0.0, 0.25, best)
			_height[i] = h
			# biome
			var b := "grass"
			if best <= 0.0:
				b = "ocean"
			elif best < 0.04:
				b = "beach"
			else:
				if forest.get_noise_2d(p.x, p.y) > 0.15:
					b = "forest"
				for r in regions:
					var rd := Vector2((p.x - r[0]) / r[2], (p.y - r[1]) / r[3])
					if rd.length() < 1.0:
						b = r[4]
				if h > 10.0 and b != "desert":
					b = "mountain"
				if p.y < 175.0 or p.y > 1030.0:
					b = "snow"
			_biome[i] = BIOMES.find(b)

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
