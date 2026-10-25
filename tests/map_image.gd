extends Node
const Terrain = preload("res://scripts/core/terrain.gd")
func _ready() -> void:
	Terrain.ensure()
	var img := Image.create(800, 600, false, Image.FORMAT_RGB8)
	for y in 600:
		for x in 800:
			var p := Vector2(x * 2, y * 2)
			var b := Terrain.biome(p)
			var c: Color = Terrain.BIOME_COLOR[b]
			var h := Terrain.height(p)
			if b != "ocean":
				c = c.darkened(clampf(-h * 0.0 + (h / 30.0), 0, 0.5))
			img.set_pixel(x, y, c)
	for sid in Data.settlements:
		var d: Dictionary = Data.settlements[sid]
		var col := Color.RED
		match d.type:
			"town": col = Color(1, 0, 1)
			"castle": col = Color(0, 0, 0)
			"village": col = Color(1, 1, 0)
			"ruin": col = Color(1, 1, 1)
		var px := int(d.pos.x / 2)
		var py := int(d.pos.y / 2)
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				img.set_pixel(clampi(px + dx, 0, 799), clampi(py + dy, 0, 599), col)
	img.save_png("/tmp/claude-0/map.png")
	get_tree().quit()
