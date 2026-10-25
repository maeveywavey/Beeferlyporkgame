extends Node
## Headless smoke test of the world simulation.
const Roster = preload("res://scripts/core/roster.gd")
const Terrain = preload("res://scripts/core/terrain.gd")

func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	Terrain.ensure()
	print("terrain built in ", Time.get_ticks_msec() - t0, " ms")
	# all settlements on land
	for sid in Data.settlements:
		var pos: Vector2 = Data.settlements[sid].pos
		if not Terrain.is_land(pos):
			print("NOT ON LAND: ", sid, " ", pos, " lv=", Terrain.land_value(pos))
	var p := GS.create_player("Tester", "ek_refugee", "earth", Color(0.8,0.6,0.5), Color(0.1,0.1,0.1))
	GS.new_game(p)
	print("parties: ", GS.parties.size())
	t0 = Time.get_ticks_msec()
	for i in 24 * 60:
		GS.sim.advance(1.0)
	print("60 days simulated in ", Time.get_ticks_msec() - t0, " ms")
	print("date: ", GS.date_string(), " parties: ", GS.parties.size())
	var kinds := {}
	for id in GS.parties:
		kinds[GS.parties[id].kind] = kinds.get(GS.parties[id].kind, 0) + 1
	print(kinds)
	var owners := {}
	for sid in GS.settlements:
		owners[GS.settlements[sid].faction] = owners.get(GS.settlements[sid].faction, 0) + 1
	print("settlements by faction: ", owners)
	for line in GS.log_lines.slice(-200):
		print("  ", line.t)
	var ok := GS.save_game("user://test.sav")
	print("save ok: ", ok)
	print("load ok: ", GS.load_game("user://test.sav"))
	print("parties after load: ", GS.parties.size())
	get_tree().quit()
