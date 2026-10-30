extends RefCounted
## World map simulation: party movement and AI, encounters between parties,
## sieges, campaigns, spawning, and daily/weekly upkeep.

const BendingWork = preload("res://scripts/core/bending_work.gd")
const AvatarSys = preload("res://scripts/core/avatar.gd")
const Roster = preload("res://scripts/core/roster.gd")
const Terrain = preload("res://scripts/core/terrain.gd")
const AutoResolve = preload("res://scripts/core/auto_resolve.gd")
const Economy = preload("res://scripts/core/economy.gd")
const Quests = preload("res://scripts/core/quests.gd")
const Story = preload("res://scripts/story/story.gd")
const Fealty = preload("res://scripts/core/fealty.gd")

const CONTACT := 3.0
const SIGHT := 60.0
const SIEGE_PREP_HOURS := 30.0

var _encounter_accum := 0.0
var _last_hour := -1
var _last_day := -1

# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------
func biome_at(pos: Vector2) -> String:
	return Terrain.biome(pos)

func party_power(p: Dictionary) -> float:
	var pw := Roster.power(p.roster)
	if p.id == "player":
		pw += 8.0 + GS.player.level * 0.6 + GS.player.companions.size() * 6.0
	elif p.lord != "":
		pw += Data.lord_power(p.lord)
	return pw

func party_size(p: Dictionary) -> int:
	if p.id == "player":
		return GS.party_size()
	return Roster.total(p.roster) + (1 if p.lord != "" else 0)

func party_speed(p: Dictionary) -> float:
	var n := maxi(1, party_size(p))
	var base := 9.0
	var mounted := float(Roster.count_mounted(p.roster)) / float(n)
	base *= 1.0 + 0.3 * mounted
	# Small parties travel fast; big armies are slow (as in Mount & Blade)
	base *= 1.0 - minf(0.4, n * 0.005)
	var wounded := float(Roster.wounded(p.roster)) / float(n)
	base *= 1.0 - 0.2 * wounded
	match p.kind:
		"player":
			base *= 1.08 + GS.skill("pathfinding") * 0.03
			if GS.player.equip.get("mount", "") != "":
				base *= 1.05
			# Ice roads, levelled roads, a glider's eye (bending work)
			base *= maxf(1.0, BendingWork.buff("swift"))
		"caravan": base *= 0.8
		"villager": base *= 0.7
		"bandit": base *= 0.85
		"pilgrim": return 24.0
	base *= p.get("speed_mult", 1.0)
	return base * Terrain.speed_mult(p.pos)

func parties_near(pos: Vector2, radius: float) -> Array:
	var out := []
	for id in GS.parties:
		var p: Dictionary = GS.parties[id]
		if p.pos.distance_to(pos) <= radius:
			out.append(p)
	return out

func settlement_pos(sid: String) -> Vector2:
	return Data.settlements[sid].pos

# ---------------------------------------------------------------------------
# Time
# ---------------------------------------------------------------------------
## Advance the world by dt game hours.
func advance(dt: float) -> void:
	if dt <= 0.0:
		return
	# Sub-step large jumps so movement and encounters stay stable.
	var steps := int(ceil(dt / 0.25))
	var sdt := dt / steps
	for i in steps:
		GS.hours += sdt
		_move_all(sdt)
		_encounter_accum += sdt
		if _encounter_accum >= 0.1:
			_encounter_accum = 0.0
			_check_encounters()
		var h := int(GS.hours)
		if h != _last_hour:
			_last_hour = h
			_hourly()
		var d := GS.day()
		if d != _last_day:
			if _last_day >= 0:
				_daily()
				if d % 7 == 0:
					_weekly()
			_last_day = d
		if not GS.game_active:
			return

func reset_clock() -> void:
	_last_hour = int(GS.hours)
	_last_day = GS.day()

func _move_all(dt: float) -> void:
	for id in GS.parties:
		var p: Dictionary = GS.parties[id]
		if id == "player":
			if GS.player.get("captive_until", -1.0) > GS.hours:
				continue
		if GS.hours < p.get("wait_until", 0.0):
			continue
		var dest: Vector2 = p.target
		if p.target_party != "":
			if GS.parties.has(p.target_party):
				dest = GS.parties[p.target_party].pos
			else:
				p.target_party = ""
				p.moving = false
				if id != "player":
					p.next_think = 0.0
				continue
		elif p.target_settlement != "":
			dest = settlement_pos(p.target_settlement)
		if not p.moving:
			continue
		var to: Vector2 = dest - p.pos
		var dist := to.length()
		var step := party_speed(p) * dt
		if dist <= step or dist < 0.01:
			p.pos = dest
			_on_arrive(p)
		else:
			p.pos += to / dist * step
		p.pos.x = clampf(p.pos.x, 2.0, Data.MAP_W - 2.0)
		p.pos.y = clampf(p.pos.y, 2.0, Data.MAP_H - 2.0)

func _on_arrive(p: Dictionary) -> void:
	if p.target_party != "":
		return  # contact handled by encounters
	p.moving = false
	if p.id == "player":
		if p.target_settlement != "":
			var sid: String = p.target_settlement
			p.target_settlement = ""
			GS.player_arrived.emit(sid)
		return
	p.next_think = 0.0
	if p.target_settlement != "":
		_ai_arrive_settlement(p, p.target_settlement)

# ---------------------------------------------------------------------------
# Encounters
# ---------------------------------------------------------------------------
func _check_encounters() -> void:
	var ids := GS.parties.keys()
	var pp: Dictionary = GS.parties.get("player", {})
	var player_free: bool = not pp.is_empty() and GS.player.get("captive_until", -1.0) <= GS.hours
	for i in ids.size():
		if not GS.parties.has(ids[i]):
			continue
		var a: Dictionary = GS.parties[ids[i]]
		for j in range(i + 1, ids.size()):
			if not GS.parties.has(ids[j]) or not GS.parties.has(ids[i]):
				continue
			var b: Dictionary = GS.parties[ids[j]]
			if a.pos.distance_to(b.pos) > CONTACT:
				continue
			if a.id == "player" or b.id == "player":
				if not player_free:
					continue
				var inside: String = GS.player.get("inside", "")
				if inside != "" and not GS.at_war(GS.settlements[inside].faction, GS.player_faction()):
					continue
				var other: Dictionary = b if a.id == "player" else a
				var hunting_player: bool = other.target_party == "player" and GS.parties_hostile(pp, other)
				if pp.target_party == other.id or hunting_player:
					if GS.hours < other.get("ignore_player_until", 0.0) and pp.target_party != other.id:
						continue
					pp.target_party = ""
					pp.moving = false
					GS.player_encounter.emit(other.id)
					return
				continue
			if a.kind == "pilgrim" or b.kind == "pilgrim":
				continue
			if GS.parties_hostile(a, b) and (a.target_party == b.id or b.target_party == a.id):
				_ai_battle(a, b)

func _ai_battle(a: Dictionary, b: Dictionary) -> void:
	var res := AutoResolve.resolve([a.id], [b.id])
	var winner: Dictionary = a if res.winner == "a" else b
	var loser: Dictionary = b if res.winner == "a" else a
	# Winner takes wounded prisoners
	for s in loser.roster:
		if s.w > 0 and Roster.total(winner.prisoners) < 40 and winner.kind in ["lord", "bandit"]:
			Roster.add(winner.prisoners, s.id, mini(s.w, 40 - Roster.total(winner.prisoners)), s.w)
	winner.gold += int(loser.gold * 0.6)
	winner.target_party = ""
	winner.next_think = 0.0
	if winner.kind == "lord" or loser.kind == "lord":
		var lname: String = _display_name(loser)
		var wname: String = _display_name(winner)
		var near := _nearest_settlement_name(loser.pos)
		GS.log_msg("%s defeated %s near %s." % [wname, lname, near], Color(0.85, 0.8, 0.7))
	on_party_defeated(loser.id, party_faction_of(winner))

func party_faction_of(p: Dictionary) -> String:
	return GS.party_faction(p)

func _display_name(p: Dictionary) -> String:
	if p.lord != "":
		return Data.lords[p.lord].name
	return p.name

func _nearest_settlement_name(pos: Vector2) -> String:
	var best := ""
	var bd := INF
	for sid in Data.settlements:
		var d: float = Data.settlements[sid].pos.distance_to(pos)
		if d < bd:
			bd = d
			best = sid
	return Data.settlements[best].name if best != "" else "the wilds"

## Remove a defeated party and handle consequences.
func on_party_defeated(pid: String, victor_faction: String) -> void:
	if not GS.parties.has(pid):
		return
	var p: Dictionary = GS.parties[pid]
	Story.on_party_defeated(p, victor_faction)
	if p.lord != "":
		var lr: Dictionary = GS.lords[p.lord]
		lr.party = ""
		lr.respawn_at = GS.hours + 72.0 + randf() * 72.0
		if victor_faction == GS.player_faction() or victor_faction == "player":
			GS.change_lord_rel(p.lord, -8)
	# End sieges this party led
	for sid in GS.settlements:
		var s: Dictionary = GS.settlements[sid]
		if not s.siege.is_empty() and s.siege.get("leader", "") == pid:
			_end_siege(sid, false)
	remove_party(pid)

func remove_party(pid: String) -> void:
	GS.parties.erase(pid)
	for id in GS.parties:
		var o: Dictionary = GS.parties[id]
		if o.target_party == pid:
			o.target_party = ""
			o.moving = false
			o.next_think = 0.0

# ---------------------------------------------------------------------------
# Hourly / daily / weekly
# ---------------------------------------------------------------------------
func _hourly() -> void:
	# AI thinking
	for id in GS.parties.keys():
		if not GS.parties.has(id) or id == "player":
			continue
		var p: Dictionary = GS.parties[id]
		if GS.hours >= p.next_think:
			p.next_think = GS.hours + randf_range(1.5, 3.5)
			_think(p)
	# Lords respawn
	for lid in GS.lords:
		var lr: Dictionary = GS.lords[lid]
		if lr.party == "" and GS.hours >= lr.respawn_at and not lr.get("held", false):
			spawn_lord(lid, 0.35)
	_update_sieges()
	# Player hit points recover slowly
	if GS.player.hp < GS.max_hp():
		GS.player.hp = mini(GS.max_hp(), GS.player.hp + maxi(1, int(GS.max_hp() * 0.01)))
	# Captivity
	var cu: float = GS.player.get("captive_until", -1.0)
	if cu > 0.0 and GS.hours >= cu:
		GS.player.captive_until = -1.0
		var pp: Dictionary = GS.player_party()
		pp.pos = Terrain.random_land_near(pp.pos, 30.0)
		pp.moving = false
		GS.log_msg("You managed to escape your captors!", Color(0.6, 1, 0.6))
	_hourly_cosmic()

## Eclipses and comets: announced by astronomers days ahead, then felt.
func _hourly_cosmic() -> void:
	var d := GS.day()
	var h := GS.hour_of_day()
	for e in GS.flags.get("cosmic", []):
		var key := "cosmic_%s_%d" % [e.kind, e.day]
		if d == e.day - 5 and not GS.flags.has(key + "_warn"):
			GS.flags[key + "_warn"] = true
			match e.kind:
				"lunar": GS.log_msg("Water Tribe astronomers predict an eclipse of the full moon in five days (%s). For a few hours that night the moon will be hidden, and its strength with it." % GS.day_name(e.day), Color(0.7, 0.75, 1))
				"comet": GS.log_msg("The Fire Sages of Crescent Island announce the return of the Great Comet, once in a hundred years. In five days it will cross the sky, and every firebender will burn as never in their life.", Color(1, 0.55, 0.3))
		if d == e.day and h >= e.from and not GS.flags.has(key):
			GS.flags[key] = true
			match e.kind:
				"lunar": GS.log_msg("The full moon turns the colour of rust. Waterbenders lose the full moon's strength until it clears.", Color(0.85, 0.5, 0.5))
				"comet":
					GS.log_msg("The Great Comet blazes across the sky, its tail brighter than the moon. Firebenders feel it in their breath.", Color(1, 0.45, 0.2))
					# Fire Nation hawks seize the moment if a war is on
					for k in Data.KINGDOMS:
						if GS.at_war("fire_nation", k):
							_start_campaign("fire_nation", true)
							break

func _daily() -> void:
	_daily_events()
	AvatarSys.daily()
	Story.fire("daily")
	_daily_diplomacy()
	Economy.daily_update()
	_daily_settlements()
	_daily_lords()
	_daily_spawns()
	_daily_campaigns()
	if GS.day() % 7 == 3:
		Fealty.weekly()
	_daily_player()
	Quests.daily()
	if GS.day() % 3 == 0 and GS.game_active:
		GS.save_game(GS.AUTOSAVE_PATH)
	if GS.day() % 3 == 0:
		for sid in GS.settlements:
			if randf() < 0.3:
				Economy.refresh_tavern(sid)
	var cycle := int((GS.day() + 7) / 28)
	if GS.is_full_moon() and not GS.flags.has("moon_%d" % cycle):
		GS.flags["moon_%d" % cycle] = true
		GS.log_msg("Tonight the moon is full. Waterbenders will be at their strongest.", Color(0.7, 0.85, 1))

func _weekly() -> void:
	var pp: Dictionary = GS.player_party()
	var wages := int(Roster.wages(pp.roster) * (1.0 - GS.skill("leadership") * 0.05))
	for c in GS.player.companions:
		wages += 15
	wages += Economy.garrison_wages()
	var income := Economy.fief_income()
	if income > 0:
		GS.add_gold(income)
		GS.log_msg("Your fiefs brought in %d gold in taxes." % income, Color(0.9, 0.85, 0.4))
	var tribute := Fealty.player_income()
	if tribute > 0:
		GS.add_gold(tribute)
		GS.log_msg("Communities under your protection sent %d gold in tribute." % tribute, Color(0.9, 0.85, 0.4))
	if GS.player.get("status", "") == "mercenary":
		var pay := 40 + GS.party_size() * 4
		GS.add_gold(pay)
		GS.log_msg("You received %d gold as your mercenary pay." % pay, Color(0.9, 0.85, 0.4))
	if wages > 0:
		if GS.player.gold >= wages:
			GS.add_gold(-wages)
			GS.log_msg("You paid %d gold in wages." % wages, Color(0.9, 0.8, 0.6))
		else:
			GS.add_gold(-GS.player.gold)
			GS.player.morale = maxf(0.0, GS.player.morale - 20.0)
			GS.log_msg("You could not pay your troops' wages! Morale plummets.", Color(1, 0.4, 0.3))

func _daily_events() -> void:
	for ev in Data.world_events:
		var key := "event_%d" % ev.day
		if GS.day() < ev.day or GS.flags.has(key):
			continue
		GS.flags[key] = true
		GS.log_msg(ev.text, Color(1, 0.85, 0.55))
		if ev.has("campaign"):
			var f: String = ev.campaign[0]
			var target: String = ev.campaign[1]
			if GS.at_war(f, GS.settlements[target].faction):
				_force_campaign(f, target, ev.get("leaders", []))
		match ev.get("effect", ""):
			"north_debate":
				# The North's choice depends on how the war at sea has gone and on
				# whether the player has made friends in Agna Qel'a.
				var lean := 0.35 + float(GS.player.get("faction_rel", {}).get("northern_water", 0)) / 200.0
				if not GS.at_war("fire_nation", "southern_water"):
					lean = 0.0
				if randf() < lean:
					GS.declare_war("northern_water", "fire_nation")
					GS.log_msg("Commander Iluq carries the vote. The Northern Water Tribe sails to aid the South.", Color(0.6, 0.8, 1))
				else:
					GS.log_msg("Chief Tulok keeps the North neutral. Commander Iluq walks out of the council hall.", Color(0.6, 0.8, 1))
			"hard_winter":
				for sid in GS.settlements:
					if Data.settlements[sid].type == "village":
						GS.settlements[sid].prosperity = maxf(5.0, GS.settlements[sid].prosperity - 8.0)

func _force_campaign(f: String, target: String, leaders: Array) -> void:
	GS.campaigns[f] = {"target": target, "until": GS.hours + 24.0 * 25.0}
	for lid in GS.lords:
		var lr: Dictionary = GS.lords[lid]
		if lr.faction != f or lr.party == "" or not GS.parties.has(lr.party):
			continue
		var p: Dictionary = GS.parties[lr.party]
		if Data.lords[lid].get("no_offense", false) and not leaders.has(lid):
			continue
		if leaders.has(lid) or Roster.total(p.roster) > _lord_target_size(lid) * 0.5:
			p.campaign = target
			p.next_think = 0.0
			if leaders.has(lid):
				# Story leaders arrive with a full army
				var tree: Array = GS.culture_tree(Data.factions[f].culture)
				while Roster.total(p.roster) < _lord_target_size(lid) * 1.3:
					Roster.add(p.roster, tree[mini(tree.size() - 1, randi() % tree.size())], 1)

## Wars and truces shift over time from the start. Long wars grow weary;
## long peaces grow brittle, between neighbours and by the temper of their
## rulers. The Air Nomads never take part, and nobody picks a fight with the
## Sun Warriors without a reckless ruler.
func _daily_diplomacy() -> void:
	var ks: Array = Data.KINGDOMS
	for i in ks.size():
		for j in range(i + 1, ks.size()):
			var a: String = ks[i]
			var b: String = ks[j]
			if Data.is_peaceful(a) or Data.is_peaceful(b):
				continue
			var since_key: String = "rel_since_" + a + "|" + b
			var since: int = GS.flags.get(since_key, GS.day())
			if not GS.flags.has(since_key):
				GS.flags[since_key] = since
			var lasted := GS.day() - since
			if GS.at_war(a, b):
				# War-weariness grows with time; a side that is losing land sues sooner
				var losing := maxf(_land_loss(a), _land_loss(b))
				if lasted > 30 and randf() < 0.008 + losing * 0.04:
					GS.make_peace(a, b)
					GS.flags[since_key] = GS.day()
			elif lasted > 40 and _neighbours(a, b) and randf() < 0.002 + 0.008 * maxf(Fealty.ruler_aggression(a), Fealty.ruler_aggression(b)):
				# Nobody opens a third front, nobody kicks a kingdom already on its
				# knees, and the Sun Warriors are left alone by the sane
				var sun_ok: bool = not (Data.factions[a].get("protected", false) or Data.factions[b].get("protected", false)) or _reckless(a if Data.factions[b].get("protected", false) else b, b if Data.factions[b].get("protected", false) else a)
				if sun_ok and _wars_of(a) < 2 and _wars_of(b) < 2 and _land_loss(a) < 0.4 and _land_loss(b) < 0.4:
					GS.declare_war(a, b)
					GS.flags[since_key] = GS.day()

## Two powers are neighbours if any of their seats lie within reach of each
## other. Only neighbours start wars on their own.
func _neighbours(a: String, b: String) -> bool:
	for x in GS.faction_settlements(a):
		for y in GS.faction_settlements(b):
			if Data.settlements[x].pos.distance_to(Data.settlements[y].pos) < 340.0:
				return true
	return false

## Whether f would dare attack the protected faction p: its ruler is reckless
## (aggression 0.8 or more) and at least as strong, or it is overwhelmingly
## stronger whoever rules it.
func _reckless(f: String, p: String) -> bool:
	var mine := Fealty.strength(f)
	var theirs := maxi(1, Fealty.strength(p))
	return (Fealty.ruler_aggression(f) >= 0.8 and mine >= theirs) or mine >= theirs * 3

func _wars_of(f: String) -> int:
	var n := 0
	for k in Data.KINGDOMS:
		if k != f and GS.at_war(f, k):
			n += 1
	return n

## Fraction of a kingdom's original towns and castles it has lost (0..1).
func _land_loss(f: String) -> float:
	var orig := 0
	var held := 0
	for sid in Data.settlements:
		var d: Dictionary = Data.settlements[sid]
		if not d.type in ["town", "castle"]:
			continue
		if d.faction == f:
			orig += 1
			if GS.settlements[sid].faction == f:
				held += 1
	return 0.0 if orig == 0 else 1.0 - float(held) / orig

func _daily_settlements() -> void:
	for sid in GS.settlements:
		var s: Dictionary = GS.settlements[sid]
		var d: Dictionary = Data.settlements[sid]
		if d.type == "ruin":
			continue
		var looted: bool = s.looted_until > GS.hours
		s.prosperity = clampf(s.prosperity + (randf_range(-0.3, 0.4) if not looted else -0.3), 5.0, 100.0)
		if not s.siege.is_empty() or d.type == "temple":
			continue
		if d.type == "village":
			if not looted and s.volunteers < 6 + int(s.relation / 10.0):
				if randf() < 0.6:
					s.volunteers += 1
			if not looted and randf() < 0.2 and d.has("bound"):
				spawn_villagers(sid)
		elif s.owner != "player":
			if sid == "ba_sing_se" and s.volunteers < 12 and randf() < 0.7:
				s.volunteers += 1   # the Lower Ring always has hungry hands
			var cap := 260 if d.type == "town" else 150
			if Roster.total(s.garrison) < cap:
				var tree: Array = GS.culture_tree(_faction_culture(s.faction, d.culture))
				for i in (3 if d.type == "town" else 2):
					Roster.add(s.garrison, tree[mini(tree.size() - 1, randi() % 3)], 1)
			Roster.heal_fraction(s.garrison, 0.3)
		else:
			Roster.heal_fraction(s.garrison, 0.3)
			Roster.give_xp(s.garrison, 2)

func _faction_culture(faction: String, fallback: String) -> String:
	if Data.factions.has(faction) and faction in Data.KINGDOMS:
		return Data.factions[faction].culture
	return fallback

func _daily_lords() -> void:
	for lid in GS.lords:
		var lr: Dictionary = GS.lords[lid]
		if lr.party == "" or not GS.parties.has(lr.party):
			continue
		var p: Dictionary = GS.parties[lr.party]
		var target := _lord_target_size(lid)
		Roster.heal_fraction(p.roster, 0.2)
		Roster.give_xp(p.roster, 6)
		# AI upgrades
		for s in p.roster.duplicate():
			var up := Roster.upgradable_count(s)
			if up > 0:
				var opts: Array = Data.troop_upgrades(s.id)
				Roster.upgrade(p.roster, s.id, opts.pick_random(), up)
		# Recruit if in friendly territory
		var near_friendly := false
		for sid in GS.settlements:
			if GS.settlements[sid].faction == lr.faction and Data.settlements[sid].pos.distance_to(p.pos) < 150.0:
				near_friendly = true
				break
		if near_friendly and Roster.total(p.roster) < target:
			var culture: String = Data.lords[lid].get("culture", Data.factions[lr.faction].culture)
			var tree: Array = GS.culture_tree(culture)
			var n := 3 + randi() % 5
			for i in n:
				Roster.add(p.roster, tree[mini(tree.size() - 1, int(pow(randf(), 2.0) * tree.size()))], 1)
		p.gold += 20
		# Release prisoners now and then (ransomed)
		if Roster.total(p.prisoners) > 0 and randf() < 0.2:
			p.prisoners.clear()

func _lord_target_size(lid: String) -> int:
	var base: int = Data.lords[lid].troops
	var fiefs := 0
	for sid in GS.settlements:
		if GS.settlements[sid].owner == lid:
			fiefs += 1
	return int(base * (0.9 + 0.05 * fiefs))

func _daily_spawns() -> void:
	# Bandits
	var counts := {}
	for id in GS.parties:
		var p: Dictionary = GS.parties[id]
		if p.kind == "bandit" and p.spawn >= 0:
			counts[p.spawn] = int(counts.get(p.spawn, 0)) + 1
	for i in Data.bandit_spawns.size():
		if int(counts.get(i, 0)) < 3 and randf() < 0.35:
			spawn_bandit(i)
	# Caravans
	var caravans := {}
	for id in GS.parties:
		var p: Dictionary = GS.parties[id]
		if p.kind == "caravan":
			caravans[p.home] = int(caravans.get(p.home, 0)) + 1
	for sid in GS.settlements:
		if Data.settlements[sid].type == "town" and GS.settlements[sid].siege.is_empty():
			if int(caravans.get(sid, 0)) < 2 and randf() < 0.2:
				spawn_caravan(sid)
	# Air Nomad pilgrims
	var pilgrims := 0
	for id in GS.parties:
		if GS.parties[id].kind == "pilgrim":
			pilgrims += 1
	if pilgrims < 2 and randf() < 0.3:
		spawn_pilgrims()

func _daily_player() -> void:
	var pp: Dictionary = GS.player_party()
	var pl: Dictionary = GS.player
	# Food (a firebender cooking for everyone stretches the stores)
	var need := int(ceil(GS.party_size() / 10.0))
	if BendingWork.buff("fed") > 0.0:
		need = int(ceil(need / 2.0))
	var food_types := []
	for g in pl.goods:
		if Data.goods[g].food and pl.goods[g] > 0:
			food_types.append(g)
	var eaten := 0
	var guard := 0
	while eaten < need and not food_types.is_empty() and guard < 200:
		guard += 1
		var g: String = food_types[eaten % food_types.size()]
		if int(pl.goods.get(g, 0)) > 0:
			GS.add_good(g, -1)
			eaten += 1
		else:
			food_types.erase(g)
	var starving := eaten < need
	if starving:
		GS.log_msg("Your party is starving! Buy food at a market.", Color(1, 0.4, 0.3))
	# Morale
	var variety := 0
	for g in pl.goods:
		if Data.goods[g].food:
			variety += 1
	var target := 50.0 + GS.skill("leadership") * 5.0 + mini(variety, 5) * 3.0 - Roster.total(pp.roster) * 0.35
	if pl.companions.has("ukiuk"):
		target += 6.0   # terrible jokes, told well
	if starving:
		target -= 40.0
	target += pl.get("victory_morale", 0.0)
	pl.victory_morale = maxf(0.0, pl.get("victory_morale", 0.0) - 2.0)
	pl.morale = clampf(pl.morale + (target - pl.morale) * 0.2, 0.0, 100.0)
	if pl.morale < 25.0 and Roster.total(pp.roster) > 0:
		var deserters := 1 + randi() % 3
		var lost := 0
		for i in deserters:
			var tid := Roster.random_troop(pp.roster)
			if tid != "":
				lost += Roster.remove(pp.roster, tid, 1)
		if lost > 0:
			GS.log_msg("%d of your troops deserted in the night." % lost, Color(1, 0.5, 0.35))
	# Healing
	var resting: bool = not pp.moving and _nearby_friendly_settlement(pp.pos) != ""
	var heal := 0.12 + GS.skill("healing") * 0.03 + Roster.count_healers(pp.roster) * 0.01
	if resting:
		heal *= 1.6
	Roster.heal_fraction(pp.roster, minf(0.9, heal))
	Roster.heal_fraction(pp.prisoners, 0.1)
	for cid in pl.companions:
		var cs: Dictionary = GS.companion_state(cid)
		if cs.wounded and randf() < 0.35 + GS.skill("healing") * 0.05:
			cs.wounded = false
	# Training
	var trainer := GS.skill("trainer")
	if trainer > 0:
		Roster.give_xp(pp.roster, trainer * 3)
	# Fief garrisons get a trickle of volunteers
	for sid in GS.settlements:
		var s: Dictionary = GS.settlements[sid]
		if s.owner == "player" and Data.settlements[sid].type != "village" and randf() < 0.5:
			Roster.add(s.garrison, Data.culture_recruit.get(Data.settlements[sid].culture, "ek_peasant"), 1)
	# Overweight prisoners escape
	while Roster.total(pp.prisoners) > GS.prisoner_limit():
		var tid := Roster.random_troop(pp.prisoners, false)
		Roster.remove(pp.prisoners, tid, 1)

func _nearby_friendly_settlement(pos: Vector2) -> String:
	for sid in Data.settlements:
		if Data.settlements[sid].pos.distance_to(pos) < 6.0 and not GS.at_war(GS.settlements[sid].faction, GS.player_faction()):
			return sid
	return ""

# ---------------------------------------------------------------------------
# AI
# ---------------------------------------------------------------------------
func _think(p: Dictionary) -> void:
	match p.kind:
		"lord": _think_lord(p)
		"bandit": _think_bandit(p)
		"caravan": _think_caravan(p)
		"villager": _think_villager(p)
		"pilgrim": _think_pilgrim(p)

func _go_to(p: Dictionary, pos: Vector2) -> void:
	p.target = pos
	p.target_party = ""
	p.target_settlement = ""
	p.moving = true

func _go_settlement(p: Dictionary, sid: String) -> void:
	p.target_party = ""
	p.target_settlement = sid
	p.moving = true

func _chase(p: Dictionary, other_id: String) -> void:
	p.target_party = other_id
	p.target_settlement = ""
	p.moving = true

## Visible hostile parties sorted by distance: returns [threat, prey].
func _scan(p: Dictionary, sight: float = SIGHT) -> Array:
	var my := party_power(p)
	var threat := {}
	var prey := {}
	var td := INF
	var pd := INF
	for id in GS.parties:
		if id == p.id:
			continue
		var o: Dictionary = GS.parties[id]
		var d: float = o.pos.distance_to(p.pos)
		if d > sight:
			continue
		if not GS.parties_hostile(p, o):
			continue
		if id == "player" and GS.player.get("captive_until", -1.0) > GS.hours:
			continue
		if id == "player" and GS.hours < p.get("ignore_player_until", 0.0):
			continue
		if id == "player" and GS.player.get("inside", "") != "" and not GS.at_war(GS.settlements[GS.player.inside].faction, GS.player_faction()):
			continue
		var op := party_power(o)
		if op > my * 1.15 and d < td:
			td = d
			threat = o
		elif op < my * 0.85 and d < pd:
			pd = d
			prey = o
	return [threat, prey]

func _flee(p: Dictionary, threat: Dictionary) -> void:
	var away: Vector2 = (p.pos - threat.pos).normalized()
	if away == Vector2.ZERO:
		away = Vector2.from_angle(randf() * TAU)
	var dest: Vector2 = p.pos + away * 50.0
	dest = dest.clamp(Vector2(10, 10), Vector2(Data.MAP_W - 10, Data.MAP_H - 10))
	_go_to(p, dest)
	p.state = "flee"

func _think_lord(p: Dictionary) -> void:
	var lid: String = p.lord
	var faction: String = p.faction
	var ldef: Dictionary = Data.lords[lid]
	if p.state == "besiege" or p.state == "raid":
		# Committed: only break off if seriously threatened
		var sc := _scan(p, 25.0)
		if not sc[0].is_empty() and party_power(sc[0]) > party_power(p) * 1.8:
			_leave_siege(p)
			_flee(p, sc[0])
		return
	# Armies keep to their own and their tributaries' lands unless marching on
	# a campaign: no chasing a bandit band across the sea
	var on_campaign: bool = p.get("campaign", "") != "" and GS.campaigns.get(faction, {}).get("target", "") == p.campaign
	if not on_campaign and _home_distance(p.pos, faction) > LEASH:
		var back := _friendly_fief_near(p)
		if back != "":
			_go_settlement(p, back)
			p.state = "return"
			return
	var scan := _scan(p)
	var threat: Dictionary = scan[0]
	var prey: Dictionary = scan[1]
	if not threat.is_empty():
		_flee(p, threat)
		return
	if not prey.is_empty() and prey.kind in ["villager", "caravan"] and ldef.aggression < 0.35:
		prey = {}
	if not prey.is_empty() and not on_campaign and _home_distance(prey.pos, faction) > LEASH * 0.8:
		prey = {}
	if not prey.is_empty() and (prey.kind != "player" or randf() < ldef.aggression + 0.3):
		_chase(p, prey.id)
		p.state = "chase"
		return
	# Campaign
	var camp: Dictionary = GS.campaigns.get(faction, {})
	if not camp.is_empty() and p.get("campaign", "") == camp.target:
		var tsid: String = camp.target
		if GS.settlements[tsid].faction == faction:
			p.campaign = ""
		else:
			var tpos: Vector2 = Data.settlements[tsid].pos
			if p.pos.distance_to(tpos) < 8.0:
				_begin_siege(p, tsid)
			else:
				_go_to(p, tpos + (p.pos - tpos).normalized() * 5.0)
				p.state = "campaign"
			return
	# Defend besieged friendly settlements
	for sid in GS.settlements:
		var s: Dictionary = GS.settlements[sid]
		if (s.faction == faction or Fealty.overlord(s.faction) == faction) and not s.siege.is_empty():
			if Data.settlements[sid].pos.distance_to(p.pos) < 320.0 and GS.parties.has(s.siege.get("leader", "")):
				var besieger: Dictionary = GS.parties[s.siege.leader]
				if party_power(p) > party_power(besieger) * 0.7:
					_chase(p, besieger.id)
					p.state = "defend"
					return
	# Low strength: go home to rest and recruit
	if Roster.total(p.roster) < _lord_target_size(lid) * 0.4:
		var home := _friendly_fief_near(p)
		if home != "":
			_go_settlement(p, home)
			p.state = "recruit"
			return
	# Raid an enemy village
	if randf() < 0.06 * ldef.aggression and Roster.total(p.roster) > 25:
		var vid := _enemy_village_near(p, 220.0)
		if vid != "":
			_go_settlement(p, vid)
			p.state = "raid_travel"
			return
	# Patrol around own lands
	if p.moving and p.state == "patrol" and p.pos.distance_to(p.target) > 5.0:
		return
	var own := GS.faction_settlements(faction)
	if own.is_empty():
		_go_to(p, Terrain.random_land_near(p.pos, 80.0))
	else:
		var sid: String = own.pick_random()
		_go_to(p, Terrain.random_land_near(Data.settlements[sid].pos, 40.0))
	p.state = "patrol"

const LEASH := 200.0

## Distance from pos to the nearest settlement of faction f or of a faction
## that pays it tribute (INF if it has none).
func _home_distance(pos: Vector2, f: String) -> float:
	var best := INF
	for sid in GS.settlements:
		var sf: String = GS.settlements[sid].faction
		if sf == f or Fealty.overlord(sf) == f:
			best = minf(best, Data.settlements[sid].pos.distance_to(pos))
	return best

## Outlaws keep away from walled towns and castles.
func _near_stronghold(pos: Vector2) -> bool:
	for sid in Data.settlements:
		var t: String = Data.settlements[sid].type
		if (t == "town" or t == "castle") and Data.settlements[sid].pos.distance_to(pos) < 25.0:
			return true
	return false

func _friendly_fief_near(p: Dictionary) -> String:
	var best := ""
	var bd := INF
	for sid in GS.settlements:
		var s: Dictionary = GS.settlements[sid]
		if s.faction == p.faction and Data.settlements[sid].type in ["town", "castle"] and s.siege.is_empty():
			var d: float = Data.settlements[sid].pos.distance_to(p.pos)
			if d < bd:
				bd = d
				best = sid
	return best

func _enemy_village_near(p: Dictionary, radius: float) -> String:
	var opts := []
	for sid in GS.settlements:
		var s: Dictionary = GS.settlements[sid]
		if Data.settlements[sid].type == "village" and GS.at_war(p.faction, s.faction) and s.looted_until < GS.hours:
			if Data.settlements[sid].pos.distance_to(p.pos) < radius:
				opts.append(sid)
	return opts.pick_random() if not opts.is_empty() else ""

func _ai_arrive_settlement(p: Dictionary, sid: String) -> void:
	p.target_settlement = ""
	var s: Dictionary = GS.settlements[sid]
	match p.kind:
		"lord":
			if p.state == "recruit" and s.faction == p.faction:
				# take some garrison troops if the garrison is large
				var take := mini(int(Roster.total(s.garrison) * 0.25), _lord_target_size(p.lord) - Roster.total(p.roster))
				for i in maxi(0, take):
					var tid := Roster.random_troop(s.garrison)
					if tid == "":
						break
					Roster.remove(s.garrison, tid, 1)
					Roster.add(p.roster, tid, 1)
				p.wait_until = GS.hours + 12.0
				p.state = "idle"
			elif p.state == "raid_travel" and GS.at_war(p.faction, s.faction):
				p.state = "raid"
				p.raid_target = sid
				p.wait_until = GS.hours + 6.0
				p.next_think = GS.hours + 6.5
				s.raider = p.id
		"caravan":
			s.prosperity = minf(100.0, s.prosperity + 2.0)
			remove_party(p.id)
		"villager":
			if p.get("leg", "to_town") == "to_town":
				s.prosperity = minf(100.0, s.prosperity + 1.0)
				p.state = "home"
				p.leg = "home"
				p.wait_until = GS.hours + 4.0
				_go_settlement(p, p.home)
			else:
				GS.settlements[p.home].prosperity = minf(100.0, GS.settlements[p.home].prosperity + 1.0)
				remove_party(p.id)

func _think_bandit(p: Dictionary) -> void:
	var scan := _scan(p, 42.0)
	if not scan[0].is_empty():
		_flee(p, scan[0])
		return
	# Give up long chases
	if p.state == "chase" and GS.hours > p.get("chase_until", 0.0):
		p.target_party = ""
		p.state = "wander"
		p.next_think = GS.hours + 3.0
		if GS.parties.has(p.get("last_prey", "")) and p.last_prey == "player":
			p.ignore_player_until = GS.hours + 6.0
	var prey: Dictionary = scan[1]
	if not prey.is_empty() and prey.kind != "lord" and p.state != "chase" and not _near_stronghold(prey.pos):
		_chase(p, prey.id)
		p.state = "chase"
		p.last_prey = prey.id
		p.chase_until = GS.hours + 8.0
		return
	if p.state == "chase" and p.target_party != "":
		return
	if p.moving and p.pos.distance_to(p.target) > 4.0 and p.target_party == "":
		return
	var center: Vector2 = p.get("anchor", p.pos)
	_go_to(p, Terrain.random_land_near(center, 70.0))
	p.state = "wander"

func _think_caravan(p: Dictionary) -> void:
	var scan := _scan(p)
	if not scan[0].is_empty():
		_flee(p, scan[0])
		return
	if p.get("dest", "") == "" or not GS.settlements.has(p.dest):
		remove_party(p.id)
		return
	if GS.at_war(p.faction, GS.settlements[p.dest].faction):
		remove_party(p.id)
		return
	_go_settlement(p, p.dest)
	p.state = "travel"

func _think_villager(p: Dictionary) -> void:
	var scan := _scan(p)
	if not scan[0].is_empty():
		_flee(p, scan[0])
		return
	if not p.moving or p.state == "flee":
		p.state = p.get("leg", "to_town")
		_go_settlement(p, p.dest if p.state == "to_town" else p.home)

## Pilgrims fly between the temples and wherever refugees gather.
func _think_pilgrim(p: Dictionary) -> void:
	if p.moving and p.pos.distance_to(p.target) > 5.0:
		return
	var sids := Data.settlements.keys().filter(func(x): return Data.settlements[x].type != "castle")
	if randf() < 0.4:
		sids = Data.settlement_ids_of_type("temple")
	var sid: String = sids.pick_random()
	_go_to(p, Data.settlements[sid].pos + Vector2(randf_range(-15, 15), randf_range(-15, 15)))
	p.wait_until = GS.hours + randf_range(2.0, 10.0)
	p.state = "wander"

# ---------------------------------------------------------------------------
# Sieges, raids and campaigns
# ---------------------------------------------------------------------------
func _begin_siege(p: Dictionary, sid: String) -> void:
	var s: Dictionary = GS.settlements[sid]
	p.state = "besiege"
	p.moving = false
	p.besieging = sid
	if s.siege.is_empty():
		s.siege = {"faction": p.faction, "leader": p.id, "hours": 0.0}
		GS.log_msg("%s has laid siege to %s!" % [_display_name(p), Data.settlements[sid].name], Color(1, 0.55, 0.35))

func _leave_siege(p: Dictionary) -> void:
	var sid: String = p.get("besieging", "")
	p.besieging = ""
	p.state = "idle"
	p.campaign = ""
	if sid != "" and GS.settlements[sid].siege.get("leader", "") == p.id:
		# hand leadership to another besieger or end
		var other := ""
		for id in GS.parties:
			if id != p.id and GS.parties[id].get("besieging", "") == sid:
				other = id
		if other != "":
			GS.settlements[sid].siege.leader = other
		else:
			_end_siege(sid, false)

func _end_siege(sid: String, _captured: bool) -> void:
	var s: Dictionary = GS.settlements[sid]
	if s.siege.is_empty():
		return
	s.siege = {}
	for id in GS.parties:
		var p: Dictionary = GS.parties[id]
		if p.get("besieging", "") == sid:
			p.besieging = ""
			p.state = "idle"
			p.campaign = ""
			p.next_think = 0.0

func _update_sieges() -> void:
	for sid in GS.settlements:
		var s: Dictionary = GS.settlements[sid]
		if s.siege.is_empty():
			# raids in progress
			continue
		if s.siege.get("leader", "") == "player":
			# the player's own siege is driven by the siege menu
			if GS.player_party().pos.distance_to(Data.settlements[sid].pos) > 12.0:
				s.siege = {}
				GS.log_msg("You abandoned the siege of %s." % Data.settlements[sid].name)
			continue
		if not GS.parties.has(s.siege.get("leader", "")):
			_end_siege(sid, false)
			continue
		s.siege.hours = s.siege.hours + 1.0
		if s.siege.hours >= SIEGE_PREP_HOURS and int(s.siege.hours) % 6 == 0:
			# Only assault with a clear advantage; otherwise keep starving them out.
			var att := 0.0
			for id in GS.parties:
				if GS.parties[id].get("besieging", "") == sid:
					att += party_power(GS.parties[id])
			var def := Roster.power(s.garrison) * 2.0 * Data.walls(sid)
			if att > def * 1.1 or s.siege.hours > 120.0:
				_resolve_assault(sid)
			elif int(s.siege.hours) % 24 == 0:
				# Starvation slowly weakens the defenders
				for st in s.garrison.duplicate():
					Roster.remove(s.garrison, st.id, int(ceil(st.n * 0.04)))
	# Raids
	for id in GS.parties.keys():
		if not GS.parties.has(id):
			continue
		var p: Dictionary = GS.parties[id]
		if p.get("state", "") == "raid" and GS.hours >= p.wait_until:
			var vid: String = p.get("raid_target", "")
			if vid != "" and GS.settlements.has(vid):
				var v: Dictionary = GS.settlements[vid]
				v.looted_until = GS.hours + 24.0 * 6.0
				v.prosperity = maxf(5.0, v.prosperity - 15.0)
				v.volunteers = 0
				v.raider = ""
				p.gold += 300
				GS.log_msg("%s has raided and burned %s." % [_display_name(p), Data.settlements[vid].name], Color(1, 0.5, 0.3))
				Fealty.protect(v.faction, p.faction)
				if v.owner == "player":
					GS.log_msg("Your village %s was raided!" % Data.settlements[vid].name, Color(1, 0.3, 0.3))
			p.state = "idle"
			p.raid_target = ""
			p.next_think = 0.0

func _resolve_assault(sid: String) -> void:
	var s: Dictionary = GS.settlements[sid]
	var attackers := []
	var defenders := []
	var pos: Vector2 = Data.settlements[sid].pos
	for id in GS.parties:
		var p: Dictionary = GS.parties[id]
		if id == "player":
			continue
		if p.get("besieging", "") == sid:
			attackers.append(id)
		elif p.pos.distance_to(pos) < 8.0 and p.kind == "lord" and not GS.at_war(p.faction, s.faction) and GS.at_war(p.faction, s.siege.faction):
			defenders.append(id)
	if attackers.is_empty():
		_end_siege(sid, false)
		return
	var res := AutoResolve.resolve(attackers, defenders, "", sid)
	var name: String = Data.settlements[sid].name
	if res.winner == "a":
		var leader: Dictionary = GS.parties[s.siege.leader] if GS.parties.has(s.siege.leader) else GS.parties[attackers[0]]
		for did in defenders:
			on_party_defeated(did, leader.faction)
		capture_settlement(sid, leader.faction, leader.lord)
		# Leave part of the army as the new garrison
		for aid in attackers:
			if not GS.parties.has(aid):
				continue
			var ap: Dictionary = GS.parties[aid]
			for st in ap.roster.duplicate():
				var n := int((st.n - st.w) * 0.35)
				if n > 0:
					Roster.remove(ap.roster, st.id, n)
					Roster.add(s.garrison, st.id, n)
	else:
		GS.log_msg("The assault on %s was repulsed!" % name, Color(0.7, 0.9, 1))
		for aid in attackers:
			if GS.parties.has(aid) and Roster.healthy(GS.parties[aid].roster) <= 0:
				on_party_defeated(aid, s.faction)
		_end_siege(sid, false)

## Transfer a settlement (and its bound villages) to a new faction.
func capture_settlement(sid: String, faction: String, new_owner: String) -> void:
	var s: Dictionary = GS.settlements[sid]
	var old_faction: String = s.faction
	var d: Dictionary = Data.settlements[sid]
	_end_siege(sid, true)
	s.faction = faction
	s.owner = new_owner
	s.siege = {}
	s.garrison = []
	if new_owner != "player" and faction in Data.KINGDOMS:
		var tree: Array = GS.culture_tree(Data.factions[faction].culture)
		for i in 30:
			Roster.add(s.garrison, tree[mini(tree.size() - 1, randi() % 3)], 1)
	var who: String = "you" if new_owner == "player" else (Data.lords[new_owner].name if Data.lords.has(new_owner) else Data.factions[faction].name)
	GS.log_msg("%s has fallen! %s now holds it for the %s." % [d.name, who.capitalize() if who == "you" else who, Data.factions[faction].name], Color(1, 0.75, 0.3))
	for vid in Data.settlements:
		if Data.settlements[vid].get("bound", "") == sid:
			GS.settlements[vid].faction = faction
			GS.settlements[vid].owner = new_owner
	# Campaigns targeting it are over
	for f in GS.campaigns.keys():
		if GS.campaigns[f].get("target", "") == sid:
			GS.campaigns.erase(f)
	if new_owner == "player":
		GS.add_renown(25)
		GS.player.honor = GS.player.get("honor", 0)
	Fealty.protect(old_faction, faction)
	# Faction eliminated?
	if old_faction in Data.KINGDOMS and GS.faction_settlements(old_faction).is_empty():
		GS.log_msg("The %s has lost all of its lands!" % Data.factions[old_faction].name, Color(1, 0.3, 0.3))

func _daily_campaigns() -> void:
	for f in Data.KINGDOMS:
		var c: Dictionary = GS.campaigns.get(f, {})
		if not c.is_empty():
			if GS.hours > c.until or GS.settlements[c.target].faction == f:
				GS.campaigns.erase(f)
				for id in GS.parties:
					var p: Dictionary = GS.parties[id]
					if p.faction == f and p.get("campaign", "") != "":
						p.campaign = ""
						if p.state == "besiege":
							_leave_siege(p)
		elif not Data.factions[f].get("protected", false):
			if randf() < 0.012 + 0.04 * Fealty.ruler_aggression(f):
				_start_campaign(f, false)

func _start_campaign(f: String, forced: bool) -> void:
	if GS.faction_settlements(f).is_empty():
		return
	# Centroid of own lands
	var center := Vector2.ZERO
	var own := GS.faction_settlements(f)
	for sid in own:
		center += Data.settlements[sid].pos
	center /= own.size()
	var best := ""
	var best_score := INF
	for sid in GS.settlements:
		var s: Dictionary = GS.settlements[sid]
		var d: Dictionary = Data.settlements[sid]
		if d.type in ["town", "castle"] and GS.at_war(f, s.faction) and s.faction in Data.KINGDOMS + ["player"] and (not Data.factions.get(s.faction, {}).get("protected", false) or _reckless(f, s.faction)):
			var score: float = d.pos.distance_to(center) + Roster.total(s.garrison) * 2.0 + randf() * 150.0
			if score < best_score:
				best_score = score
				best = sid
	if best == "":
		return
	GS.campaigns[f] = {"target": best, "until": GS.hours + 24.0 * 14.0}
	var joined := 0
	for lid in GS.lords:
		var lr: Dictionary = GS.lords[lid]
		if lr.faction != f or lr.party == "" or not GS.parties.has(lr.party):
			continue
		var p: Dictionary = GS.parties[lr.party]
		if Data.lords[lid].get("no_offense", false):
			continue
		if forced or Roster.total(p.roster) > _lord_target_size(lid) * 0.5:
			p.campaign = best
			p.next_think = 0.0
			joined += 1
	if joined == 0:
		GS.campaigns.erase(f)
		return
	var msg := "The armies of the %s march on %s!" % [Data.factions[f].name, Data.settlements[best].name]
	GS.log_msg(msg, Color(1, 0.6, 0.4))

# ---------------------------------------------------------------------------
# Spawning
# ---------------------------------------------------------------------------
func spawn_lord(lid: String, size_frac: float) -> void:
	var lr: Dictionary = GS.lords[lid]
	var ld: Dictionary = Data.lords[lid]
	var home: String = ld.home
	if GS.settlements[home].faction != lr.faction:
		var own := GS.faction_settlements(lr.faction)
		own = own.filter(func(x): return Data.settlements[x].type != "village")
		if own.is_empty():
			lr.respawn_at = GS.hours + 24.0 * 5.0
			return
		home = own.pick_random()
	var title := "Host" if ld.get("king", false) else "Army"
	var p := GS.make_party("", "%s's %s" % [ld.name, title], "lord", lr.faction, Terrain.random_land_near(Data.settlements[home].pos, 10.0))
	p.lord = lid
	p.home = home
	p.gold = 500
	var culture: String = ld.get("culture", Data.factions[lr.faction].culture)
	var tree: Array = GS.culture_tree(culture)
	var n := maxi(5, int(ld.troops * size_frac))
	for i in n:
		# bias towards mid tiers for starting armies
		var r := pow(randf(), 2.0 if size_frac >= 1.0 else 2.8)
		Roster.add(p.roster, tree[mini(tree.size() - 1, int(r * tree.size()))], 1)
	lr.party = p.id
	p.next_think = 0.0
	p.wait_until = GS.hours + randf_range(0.0, 3.0)

func spawn_bandit(idx: int) -> void:
	var sp: Dictionary = Data.bandit_spawns[idx]
	if sp.name == "Sandbenders" and GS.flags.get("sand_clan_safe", false):
		return   # Kesi's clan has water now
	var p := GS.make_party("", sp.name, "bandit", sp.faction, Terrain.random_land_near(sp.pos, 40.0))
	p.spawn = idx
	p.anchor = sp.pos
	# Outlaw bands start small and grow bolder as the war drags on
	var n := 4 + randi() % 8 + mini(10, int(GS.day() / 12))
	for i in n:
		Roster.add(p.roster, sp.troops.pick_random(), 1)
	p.gold = 50 + randi() % 150

func spawn_quest_bandits(sid: String, qid: String) -> String:
	var pos: Vector2 = Data.settlements[sid].pos
	var p := GS.make_party("", "Raiders of %s" % Data.settlements[sid].name, "bandit", "bandits", Terrain.random_land_near(pos, 35.0))
	p.anchor = p.pos
	p.quest = qid
	var pool := ["mountain_bandit", "mountain_bandit", "pirate"]
	if Data.settlements[sid].culture == "fire":
		pool = ["fn_deserter", "mountain_bandit"]
	for i in 8 + randi() % 8:
		Roster.add(p.roster, pool.pick_random(), 1)
	p.gold = 150
	return p.id

func spawn_caravan(sid: String) -> void:
	var s: Dictionary = GS.settlements[sid]
	var dests := []
	for other in Data.settlements:
		if other != sid and Data.settlements[other].type == "town" and not GS.at_war(s.faction, GS.settlements[other].faction):
			dests.append(other)
	if dests.is_empty():
		return
	var p := GS.make_party("", "%s Caravan" % Data.settlements[sid].name, "caravan", s.faction, Data.settlements[sid].pos + Vector2(3, 3))
	p.home = sid
	p.dest = dests.pick_random()
	p.gold = 400 + randi() % 400
	var tree: Array = GS.culture_tree(Data.settlements[sid].culture)
	for i in 6 + randi() % 8:
		Roster.add(p.roster, tree[mini(tree.size() - 1, randi() % 3)], 1)
	_go_settlement(p, p.dest)
	p.state = "travel"

func spawn_villagers(vid: String) -> void:
	var d: Dictionary = Data.settlements[vid]
	var p := GS.make_party("", "Villagers of %s" % d.name, "villager", GS.settlements[vid].faction, d.pos + Vector2(2, 2))
	p.home = vid
	p.dest = d.bound
	p.gold = 80
	Roster.add(p.roster, Data.culture_recruit.get(d.culture, "ek_peasant"), 4 + randi() % 6)
	_go_settlement(p, d.bound)
	p.state = "to_town"
	p.leg = "to_town"

func spawn_pilgrims() -> void:
	var temples := Data.settlement_ids_of_type("temple")
	var start: Vector2 = Data.settlements[temples.pick_random()].pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	var p := GS.make_party("", "Air Nomad Pilgrims", "pilgrim", "air_nomads", start)
	Roster.add(p.roster, "an_master", 1)
	Roster.add(p.roster, "an_monk", 2 + randi() % 3)
	Roster.add(p.roster, "an_novice", 1 + randi() % 3)
	p.next_think = 0.0
