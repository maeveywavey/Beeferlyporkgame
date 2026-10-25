extends RefCounted
## Abstract battle simulation for fights the player does not play out.
## Casualties are applied directly to the participating rosters.

const Roster = preload("res://scripts/core/roster.gd")

static func _hero_power(pid: String) -> float:
	var p: Dictionary = GS.parties.get(pid, {})
	if p.is_empty():
		return 0.0
	if pid == "player":
		var hp: float = 8.0 + GS.player.level * 0.6
		for c in GS.player.companions:
			if not GS.companion_state(c).wounded:
				hp += 6.0
		return hp
	if p.lord != "" and Data.lords.has(p.lord):
		return Data.lord_power(p.lord)
	return 0.0

static func _rosters(pids: Array, garrison: String) -> Array:
	var out := []
	for pid in pids:
		if GS.parties.has(pid):
			out.append(GS.parties[pid].roster)
	if garrison != "" and GS.settlements.has(garrison):
		out.append(GS.settlements[garrison].garrison)
	return out

static func _side_power(rosters: Array) -> float:
	var p := 0.0
	for r in rosters:
		p += Roster.power(r)
	return p

static func _side_healthy(rosters: Array) -> int:
	var n := 0
	for r in rosters:
		n += Roster.healthy(r)
	return n

## Inflict `damage` worth of casualties on a side. Returns power lost.
static func _inflict(rosters: Array, damage: float, kill_chance: float) -> float:
	var lost := 0.0
	var guard := 0
	while damage > 0.0 and guard < 500:
		guard += 1
		var total := _side_healthy(rosters)
		if total <= 0:
			break
		# pick a random healthy troop, weighted by count
		var r := randi() % total
		for ros in rosters:
			var h := Roster.healthy(ros)
			if r < h:
				var tid := Roster.random_troop(ros)
				var tp := Data.troop_power(tid)
				if damage < tp and randf() > damage / tp:
					damage = 0.0
					break
				damage -= tp
				lost += tp
				if randf() < kill_chance:
					Roster.remove(ros, tid, 1)
				else:
					Roster.wound(ros, tid, 1)
				break
			r -= h
	return lost

## side_a / side_b: arrays of party ids. garrison_x: settlement id fighting on
## that side (defending walls) or "". Returns {winner: "a"|"b", lines, power_lost_a, power_lost_b}.
static func resolve(side_a: Array, side_b: Array, garrison_a: String = "", garrison_b: String = "", tactics_a: int = 0) -> Dictionary:
	var ra := _rosters(side_a, garrison_a)
	var rb := _rosters(side_b, garrison_b)
	var hero_a := 0.0
	var hero_b := 0.0
	for pid in side_a:
		hero_a += _hero_power(pid)
	for pid in side_b:
		hero_b += _hero_power(pid)
	var wall_a := 1.8 * Data.walls(garrison_a) if garrison_a != "" else 1.0
	var wall_b := 1.8 * Data.walls(garrison_b) if garrison_b != "" else 1.0
	var tac_a := 1.0 + tactics_a * 0.04
	var lost_a := 0.0
	var lost_b := 0.0
	var start_a := _side_power(ra) + hero_a
	var start_b := _side_power(rb) + hero_b
	var winner := ""
	for round_i in 80:
		var pa := _side_power(ra)
		var pb := _side_power(rb)
		var ha := _side_healthy(ra)
		var hb := _side_healthy(rb)
		if hb <= 0 and (ha > 0 or hero_a > hero_b):
			winner = "a"
			break
		if ha <= 0:
			winner = "b"
			break
		var dmg_to_b := (pa + hero_a) * 0.12 * randf_range(0.7, 1.3) * wall_a * tac_a
		var dmg_to_a := (pb + hero_b) * 0.12 * randf_range(0.7, 1.3) * wall_b
		lost_b += _inflict(rb, dmg_to_b / wall_b, 0.45)
		lost_a += _inflict(ra, dmg_to_a / wall_a, 0.4)
	if winner == "":
		winner = "a" if _side_power(ra) + hero_a >= _side_power(rb) + hero_b else "b"
	var lines := []
	lines.append("Your side lost %d%% of its strength; the enemy lost %d%%." % [
		int(100.0 * lost_a / maxf(1.0, start_a)), int(100.0 * lost_b / maxf(1.0, start_b))])
	return {"winner": winner, "lines": lines, "power_lost_a": lost_a, "power_lost_b": lost_b}
