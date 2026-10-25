extends Node
## A simple bot that plays the campaign layer for N days to sanity-check balance.
const Roster = preload("res://scripts/core/roster.gd")
const Economy = preload("res://scripts/core/economy.gd")
const Quests = preload("res://scripts/core/quests.gd")

var bg := "ek_refugee"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		bg = args[0]
	var p := GS.create_player("Bot", bg, GS.BACKGROUNDS[bg].bends[0], Color(0.8, 0.6, 0.5), Color(0.1, 0.1, 0.1))
	GS.new_game(p)
	GS.flags.seen_help = true
	# spend starting points
	_spend_points()
	var fled := 0
	var fights_won := 0
	var fights_lost := 0
	var encounters := [""]
	GS.player_encounter.connect(func(pid): encounters[0] = pid)
	var arrived := [""]
	GS.player_arrived.connect(func(sid): arrived[0] = sid)
	var pp: Dictionary = GS.player_party()
	var dest := ""
	for step in 24 * 90:
		if GS.player.captive_until > GS.hours:
			GS.sim.advance(1.0)
			continue
		if pp.target_party == "" and step % 6 == 0 and GS.food_days() > 2.0:
			# hunt weak outlaws nearby, like a player would
			for id in GS.parties:
				var o: Dictionary = GS.parties[id]
				if o.kind == "bandit" and o.pos.distance_to(pp.pos) < 70.0 and GS.sim.party_power(o) < GS.sim.party_power(pp) * 0.8:
					pp.target_party = id
					pp.target_settlement = ""
					pp.moving = true
					dest = "hunt"
					break
		if (dest == "" or not pp.moving) and pp.target_party == "":
			dest = _choose_town()
			pp.target_settlement = dest
			pp.moving = true
		GS.sim.advance(1.0)
		if encounters[0] != "":
			var pid: String = encounters[0]
			encounters[0] = ""
			if GS.parties.has(pid) and GS.parties_hostile(pp, GS.parties[pid]) and GS.sim.party_power(GS.parties[pid]) > GS.sim.party_power(pp) * 0.95:
				var e: Dictionary = GS.parties[pid]
				var faster: bool = GS.sim.party_speed(e) > GS.sim.party_speed(pp) * 1.05
				if faster and Roster.total(pp.roster) > 0:
					for i in maxi(1, int(Roster.total(pp.roster) * 0.15)):
						var tid := Roster.random_troop(pp.roster, false)
						if tid != "":
							Roster.remove(pp.roster, tid, 1)
				e.ignore_player_until = GS.hours + 4.0
				e.target_party = ""
				fled += 1
			elif GS.parties.has(pid) and GS.parties_hostile(pp, GS.parties[pid]):
				var r := GS.auto_resolve_player([pid])
				if r.won:
					fights_won += 1
				else:
					fights_lost += 1
				GS.last_battle_result = {}
			elif GS.parties.has(pid):
				GS.parties[pid].ignore_player_until = GS.hours + 4.0
			pp.moving = true
		if arrived[0] != "":
			_visit(arrived[0])
			arrived[0] = ""
			dest = ""
		if step % 24 == 0:
			_spend_points()
			_upgrade()
		if step % (24 * 15) == 0:
			print("day %d: gold %d party %d/%d level %d renown %d morale %d food %.1f won %d lost %d fled %d" % [GS.day(), GS.player.gold, GS.party_size(), GS.party_limit(), GS.player.level, GS.player.renown, int(GS.player.morale), GS.food_days(), fights_won, fights_lost, fled])
	print("final day %d: gold %d party %d level %d renown %d won %d lost %d quests done %d" % [GS.day(), GS.player.gold, GS.party_size(), GS.player.level, GS.player.renown, fights_won, fights_lost, GS.quests.filter(func(q): return q.status == "done").size()])
	get_tree().quit()

func _choose_town() -> String:
	var pp: Dictionary = GS.player_party()
	var best := ""
	var bd := INF
	for sid in Data.settlements:
		var d: Dictionary = Data.settlements[sid]
		if d.type == "ruin" or GS.at_war(GS.settlements[sid].faction, GS.player_faction()):
			continue
		var dist: float = d.pos.distance_to(pp.pos) + randf() * 120.0
		if dist < 8.0:
			continue
		if dist < bd:
			bd = dist
			best = sid
	return best

func _visit(sid: String) -> void:
	var d: Dictionary = Data.settlements[sid]
	var s: Dictionary = GS.settlements[sid]
	Quests.on_arrive(sid)
	Quests.try_deliver(sid)
	# food: keep ~8 days
	var goods := Economy.market_goods(sid)
	var guard := 0
	while GS.food_days() < 8.0 and guard < 50 and GS.player.gold > 60:
		guard += 1
		var foods := goods.filter(func(g): return Data.goods[g].food)
		if foods.is_empty():
			break
		Economy.buy(sid, foods.pick_random())
	# recruit
	if d.type == "village" and s.looted_until < GS.hours:
		var cost := Economy.recruit_cost(sid)
		while s.volunteers > 0 and GS.party_size() < GS.party_limit() and GS.player.gold > cost + 30:
			GS.add_gold(-cost)
			Roster.add(GS.player_party().roster, Economy.recruit_troop(sid), 1)
			s.volunteers -= 1
	# sell prisoners
	if d.type == "town" and s.tavern.get("ransom", false):
		for st in GS.player_party().prisoners:
			GS.add_gold(Economy.ransom_value(st.id) * st.n)
		GS.player_party().prisoners.clear()
	# quests
	var q := Quests.generate(sid)
	if not q.is_empty() and q.type in ["deliver_letter", "bandits"]:
		Quests.accept(q)

func _spend_points() -> void:
	var pl: Dictionary = GS.player
	while pl.attr_points > 0:
		pl.attrs[["str", "cha", "int", "agi"][randi() % 4]] += 1
		pl.attr_points -= 1
	var order := ["leadership", "trainer", "ironflesh", "power_strike", "tactics", "healing", "pathfinding", "weapon_mastery"]
	var guard := 0
	while pl.skill_points > 0 and guard < 50:
		guard += 1
		var sk: String = order[randi() % order.size()]
		if pl.skills[sk] < GS.skill_cap(sk):
			pl.skills[sk] += 1
			pl.skill_points -= 1

func _upgrade() -> void:
	var roster: Array = GS.player_party().roster
	for st in roster.duplicate():
		var n := Roster.upgradable_count(st)
		if n > 0:
			var opts: Array = Data.troop(st.id).upgrades
			var tgt: String = opts.pick_random()
			var cost := Data.troop_upgrade_cost(tgt)
			n = mini(n, int((GS.player.gold - 100) / maxf(1, cost)))
			if n > 0:
				var done := Roster.upgrade(roster, st.id, tgt, n)
				GS.add_gold(-done * cost)
