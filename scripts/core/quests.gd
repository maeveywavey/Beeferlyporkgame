extends RefCounted
## Simple procedural quests offered by village elders, guild masters and lords.

const Roster = preload("res://scripts/core/roster.gd")

static func active() -> Array:
	return GS.quests.filter(func(q): return q.status == "active")

static func has_quest_from(sid: String) -> bool:
	for q in active():
		if q.giver == sid:
			return true
	return false

## Build a quest offer for a settlement, or {} if nothing is available.
static func generate(sid: String) -> Dictionary:
	var d: Dictionary = Data.settlements[sid]
	var s: Dictionary = GS.settlements[sid]
	if has_quest_from(sid):
		return {}
	if GS.day() - int(s.get("quest_day", -99)) < 3:
		return {}
	var choices := []
	match d.type:
		"village": choices = ["bandits", "deliver_goods", "deliver_goods"]
		"town": choices = ["deliver_letter", "deliver_goods", "bandits"]
		"castle": choices = ["bring_troops", "deliver_letter"]
	if choices.is_empty():
		return {}
	var type: String = choices.pick_random()
	var q := {"id": GS.new_id("q"), "type": type, "giver": sid, "status": "active",
		"deadline": GS.hours + 24.0 * 12.0, "reward": 0, "target": "", "good": "", "n": 0}
	var giver_title := "the village elder" if d.type == "village" else ("the guild master" if d.type == "town" else "the castle steward")
	match type:
		"bandits":
			q.reward = 250 + randi() % 200
			q.title = "Bandits near %s" % d.name
			q.desc = "%s says outlaws have been raiding travellers near %s. Destroy them and you will be paid %d gold." % [giver_title.capitalize(), d.name, q.reward]
		"deliver_goods":
			var pool := []
			for g in Data.goods:
				if not Data.settlements[sid].produces.has(g):
					pool.append(g)
			q.good = pool.pick_random()
			q.n = 3 + randi() % 6
			q.reward = int(Data.goods[q.good].price * q.n * 1.6) + 50
			q.title = "%d %s for %s" % [q.n, Data.goods[q.good].name, d.name]
			q.desc = "%s needs %d units of %s. Bring them within 12 days for %d gold." % [giver_title.capitalize(), q.n, Data.goods[q.good].name, q.reward]
		"deliver_letter":
			var targets := []
			for other in Data.settlements:
				var od: Dictionary = Data.settlements[other]
				if other != sid and od.type in ["town", "castle"] and not GS.at_war(GS.settlements[other].faction, GS.player_faction()):
					targets.append(other)
			if targets.is_empty():
				return {}
			q.target = targets.pick_random()
			var dist: float = d.pos.distance_to(Data.settlements[q.target].pos)
			q.reward = 60 + int(dist * 0.35)
			q.deadline = GS.hours + 24.0 * (4.0 + dist / 120.0)
			q.title = "A letter for %s" % Data.settlements[q.target].name
			q.desc = "Carry a sealed letter from %s to %s. Payment on delivery: %d gold." % [d.name, Data.settlements[q.target].name, q.reward]
		"bring_troops":
			q.n = 4 + randi() % 6
			q.reward = q.n * 60
			q.title = "Reinforcements for %s" % d.name
			q.desc = "The garrison of %s is undermanned. Bring %d trained troops (tier 2 or better) within 12 days for %d gold." % [d.name, q.n, q.reward]
	return q

## Tasks offered by lords themselves.
static func generate_lord(lid: String) -> Dictionary:
	for q in active():
		if q.get("lord", "") == lid:
			return {}
	var f: String = Data.lords[lid].faction
	var home: String = Data.lords[lid].home
	var q := {"id": GS.new_id("q"), "giver": home, "lord": lid, "status": "active",
		"deadline": GS.hours + 24.0 * 20.0, "reward": 0, "target": "", "good": "", "n": 0}
	var enemies := []
	for other in GS.lords:
		var lr: Dictionary = GS.lords[other]
		if GS.at_war(f, lr.faction) and lr.party != "" and GS.parties.has(lr.party):
			enemies.append(other)
	var villages := []
	for sid in GS.settlements:
		if Data.settlements[sid].type == "village" and GS.at_war(f, GS.settlements[sid].faction) and GS.settlements[sid].looted_until < GS.hours:
			villages.append(sid)
	if not enemies.is_empty() and (villages.is_empty() or randf() < 0.6):
		q.type = "defeat_lord"
		q.target = enemies.pick_random()
		q.reward = 700 + Data.lords[q.target].troops * 5
		q.title = "Defeat %s" % Data.lords[q.target].name
		q.desc = "%s wants the army of %s destroyed. Defeat them in battle within 20 days for %d gold." % [Data.lords[lid].name, Data.lords[q.target].name, q.reward]
	elif not villages.is_empty():
		q.type = "raid_village"
		q.target = villages.pick_random()
		q.reward = 450
		q.title = "Raid %s" % Data.settlements[q.target].name
		q.desc = "%s wants the enemy village of %s raided to weaken its lord. Reward: %d gold." % [Data.lords[lid].name, Data.settlements[q.target].name, q.reward]
	else:
		return {}
	return q

static func on_raid(sid: String) -> void:
	for q in active():
		if q.type == "raid_village" and q.target == sid:
			complete(q)

static func accept(q: Dictionary) -> void:
	GS.quests.append(q)
	GS.settlements[q.giver].quest_day = GS.day()
	if q.type == "bandits":
		var pid: String = GS.sim.spawn_quest_bandits(q.giver, q.id)
		q.target = pid
	GS.log_msg("Quest accepted: " + q.title, Color(0.9, 0.85, 0.5))

static func complete(q: Dictionary) -> void:
	q.status = "done"
	GS.add_gold(q.reward)
	GS.give_player_xp(150 + q.reward / 2)
	GS.add_renown(3)
	GS.settlements[q.giver].relation = mini(100, GS.settlements[q.giver].relation + 6)
	var owner: String = GS.settlements[q.giver].owner
	GS.change_lord_rel(owner, 2)
	if q.has("lord"):
		GS.change_lord_rel(q.lord, 8)
	GS.change_faction_rel(GS.settlements[q.giver].faction, 2)
	GS.log_msg("Quest complete: %s (+%d gold)" % [q.title, q.reward], Color(0.6, 1.0, 0.6))

static func fail(q: Dictionary) -> void:
	q.status = "failed"
	GS.settlements[q.giver].relation = maxi(-100, GS.settlements[q.giver].relation - 5)
	GS.log_msg("Quest failed: " + q.title, Color(1.0, 0.5, 0.4))

static func on_battle_won(enemy_ids: Array, defeated_lords: Array = []) -> void:
	for q in active():
		if q.type == "bandits" and enemy_ids.has(q.target):
			complete(q)
		elif q.type == "defeat_lord" and defeated_lords.has(q.target):
			complete(q)

static func on_arrive(sid: String) -> void:
	for q in active():
		if q.type == "deliver_letter" and q.target == sid:
			complete(q)

## Called from the settlement menu. Returns true if something was delivered.
static func try_deliver(sid: String) -> bool:
	var done := false
	for q in active():
		if q.giver != sid:
			continue
		if q.type == "deliver_goods" and int(GS.player.goods.get(q.good, 0)) >= q.n:
			GS.add_good(q.good, -q.n)
			complete(q)
			done = true
		elif q.type == "bring_troops":
			var eligible := 0
			for s in GS.player_party().roster:
				if Data.troop(s.id).tier >= 2:
					eligible += s.n - s.w
			if eligible >= q.n:
				var left: int = q.n
				var roster: Array = GS.player_party().roster
				Roster.sort_by_tier(roster)
				roster.reverse()
				for s in roster.duplicate():
					if left <= 0:
						break
					if Data.troop(s.id).tier >= 2:
						var moved := Roster.remove(roster, s.id, mini(left, s.n - s.w))
						Roster.add(GS.settlements[sid].garrison, s.id, moved)
						left -= moved
				complete(q)
				done = true
	return done

static func deliverable_at(sid: String) -> Array:
	var out := []
	for q in active():
		if q.giver == sid and q.type in ["deliver_goods", "bring_troops"]:
			out.append(q)
	return out

static func daily() -> void:
	for q in active():
		if GS.hours > q.deadline:
			if q.type == "bandits" and GS.parties.has(q.target):
				GS.sim.remove_party(q.target)
			fail(q)
		elif q.type == "bandits" and not GS.parties.has(q.target):
			# Someone else destroyed them
			q.status = "done"
			GS.log_msg("The bandits near %s were destroyed by someone else." % Data.settlements[q.giver].name)
