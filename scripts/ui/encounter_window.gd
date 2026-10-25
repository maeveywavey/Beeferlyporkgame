extends "res://scripts/ui/window_base.gd"
## Shown when the player's party meets another party on the map.

const Roster = preload("res://scripts/core/roster.gd")

var pid := ""
var map
var page := "main"
var note := ""

func _init() -> void:
	window_size = Vector2(780, 520)
	closable = false

func build() -> void:
	if not GS.parties.has(pid):
		close()
		return
	var p: Dictionary = GS.parties[pid]
	var pp: Dictionary = GS.player_party()
	set_title(p.name)
	var faction: String = GS.party_faction(p)
	var hostile: bool = GS.parties_hostile(pp, p)
	var info := "[b]%s[/b] — %d troops." % [Data.factions.get(faction, Data.factions.neutral).name, GS.sim.party_size(p)]
	var ratio: float = GS.sim.party_power(p) / maxf(1.0, GS.sim.party_power(pp))
	info += "  They look " + ("much weaker than you." if ratio < 0.5 else ("weaker than you." if ratio < 0.9 else ("evenly matched with you." if ratio < 1.15 else ("stronger than you." if ratio < 2.0 else "far stronger than you."))))
	content.add_child(UI.rich(info, 700))
	content.add_child(UI.rich(_composition(p), 700))
	if note != "":
		content.add_child(UI.rich("[i]%s[/i]" % note, 700))
	content.add_child(UI.sep())
	if p.kind == "avatar":
		_build_avatar(p)
	elif page == "talk" and p.lord != "":
		_build_lord_talk(p)
	elif hostile:
		_build_hostile(p)
	else:
		_build_neutral(p)

func _composition(p: Dictionary) -> String:
	var parts := []
	if p.lord != "":
		var ld: Dictionary = Data.lords[p.lord]
		var bend := "" if ld.bend == "" else " (%s)" % Data.element_name(ld.bend)
		parts.append("Led by [b]%s[/b]%s" % [ld.name, bend])
	var r: Array = p.roster.duplicate()
	Roster.sort_by_tier(r)
	var shown := 0
	for s in r:
		if shown >= 6:
			break
		parts.append("%d %s" % [s.n, Data.troop(s.id).name])
		shown += 1
	if r.size() > 6:
		parts.append("and others")
	return ", ".join(parts)

# ---------------------------------------------------------------------------
func _build_hostile(p: Dictionary) -> void:
	var pp: Dictionary = GS.player_party()
	var lead := "They are preparing to attack!" if p.target_party == "player" else "They have not noticed you yet."
	if p.lord != "":
		lead = "\"%s\"" % _hostile_line(p)
	content.add_child(UI.rich(lead, 700))
	content.add_child(UI.spacer(6))
	var healthy := Roster.healthy(pp.roster)
	content.add_child(UI.option("Charge! (fight the battle yourself)", _fight.bind(p)))
	content.add_child(UI.option("Order your troops to attack without you (auto-resolve)", _auto.bind(p), healthy > 0))
	var faster: bool = GS.sim.party_speed(p) > GS.sim.party_speed(pp) * 1.05
	var stronger: bool = GS.sim.party_power(p) > GS.sim.party_power(pp) * 0.8
	if p.target_party == "player" and faster and stronger and Roster.total(pp.roster) > 0:
		content.add_child(UI.option("Leave some troops behind to cover your escape", _sacrifice.bind(p)))
	elif p.target_party == "player" and faster and stronger:
		content.add_child(UI.option("Try to slip away alone (you will likely be caught)", _try_escape.bind(p)))
	else:
		content.add_child(UI.option("Leave", _leave.bind(p)))

func _hostile_line(p: Dictionary) -> String:
	var faction: String = p.faction
	match faction:
		"fire_nation": return ["Surrender, or be burned where you stand!", "In the name of the Fire Lord, you are under arrest!", "You'll make a fine addition to the prison rigs."].pick_random()
		"earth_kingdom": return ["You stand on Earth Kingdom soil. Prepare to fall.", "The earth itself will bury you!"].pick_random()
		"northern_water", "southern_water": return ["For the Water Tribes!", "The ocean takes all in the end. So shall we."].pick_random()
	return "Prepare yourself!"

func _gather_sides(p: Dictionary) -> Array:
	var pp: Dictionary = GS.player_party()
	var enemies := [p.id]
	var allies := []
	for id in GS.parties:
		if id == p.id or id == "player":
			continue
		var o: Dictionary = GS.parties[id]
		if o.pos.distance_to(pp.pos) > 10.0 or o.kind == "avatar":
			continue
		if GS.parties_hostile(o, pp) and not GS.parties_hostile(o, p) and o.kind in ["lord", "bandit"]:
			enemies.append(id)
		elif GS.parties_hostile(o, p) and not GS.parties_hostile(o, pp) and o.kind == "lord":
			allies.append(id)
	return [enemies, allies]

func _fight(p: Dictionary) -> void:
	_mark_aggression(p)
	var sides := _gather_sides(p)
	GS.start_battle(sides[0], sides[1], "", true)

func _auto(p: Dictionary) -> void:
	_mark_aggression(p)
	var sides := _gather_sides(p)
	GS.auto_resolve_player(sides[0], sides[1], "", true)
	var rw = load("res://scripts/ui/result_window.gd").new()
	rw.result = GS.last_battle_result
	GS.last_battle_result = {}
	map.open_window(rw)
	close()

func _mark_aggression(p: Dictionary) -> void:
	var f: String = p.faction
	if f in Data.KINGDOMS and not GS.at_war(GS.player_faction(), f):
		GS.change_faction_rel(f, -30)
		if GS.player.faction == "":
			GS.declare_war("player", f)
		GS.log_msg("You have attacked the %s! They now consider you an enemy." % Data.factions[f].name, Color(1, 0.4, 0.3))
	if p.kind in ["caravan", "villager"]:
		GS.player.honor = GS.player.get("honor", 0) - 3

func _leave(p: Dictionary) -> void:
	p.ignore_player_until = GS.hours + 4.0
	if p.target_party == "player":
		p.target_party = ""
		p.next_think = GS.hours + 4.0
	close()

func _sacrifice(p: Dictionary) -> void:
	var pp: Dictionary = GS.player_party()
	var n := maxi(1, int(Roster.total(pp.roster) * 0.15))
	var lost := 0
	for i in n:
		var tid := Roster.random_troop(pp.roster, false)
		if tid != "":
			lost += Roster.remove(pp.roster, tid, 1)
	GS.log_msg("%d of your troops stayed behind so the rest could escape." % lost, Color(1, 0.6, 0.4))
	_leave(p)

func _try_escape(p: Dictionary) -> void:
	if randf() < 0.3 + GS.player.attrs.agi * 0.02:
		GS.log_msg("You slipped away into the wilds.", Color(0.7, 1, 0.7))
		_leave(p)
	else:
		UI.clear(content)
		content.add_child(UI.rich("[b]They caught you![/b] You must fight.", 700))
		content.add_child(UI.option("Fight!", _fight.bind(p)))

# ---------------------------------------------------------------------------
func _build_neutral(p: Dictionary) -> void:
	if p.lord != "":
		var ld: Dictionary = Data.lords[p.lord]
		content.add_child(UI.rich("%s regards you. (Relation: %d)" % [ld.name, GS.lords[p.lord].relation], 700))
		content.add_child(UI.option("Speak with %s" % ld.name, func():
			page = "talk"
			refresh()))
		content.add_child(UI.option("Attack them! (this means war with the %s)" % Data.factions[p.faction].name, _confirm_attack.bind(p)))
		content.add_child(UI.option("Leave", _leave.bind(p)))
		return
	var desc := ""
	match p.kind:
		"caravan": desc = "A merchant caravan, guarded by a handful of hired swords. The merchants eye you nervously."
		"villager": desc = "Villagers on their way to market with carts of produce."
		"bandit": desc = "A ragged band who seem unsure whether to fight you."
	if p.faction == "freedom_fighters":
		desc = "\"We fight the Fire Nation. If you do too, you're welcome in our forest.\" — a boy chewing on a stalk of wheat."
	content.add_child(UI.rich(desc, 700))
	content.add_child(UI.option("Attack them!", _confirm_attack.bind(p)))
	content.add_child(UI.option("Leave them be", _leave.bind(p)))

func _confirm_attack(p: Dictionary) -> void:
	UI.clear(content)
	var f: String = p.faction
	var warn := "Attacking them will make you an enemy of the %s." % Data.factions.get(f, Data.factions.neutral).name
	if f == "freedom_fighters":
		GS.change_faction_rel("freedom_fighters", -50)
	content.add_child(UI.rich(warn, 700))
	content.add_child(UI.option("Fight the battle yourself", _fight.bind(p)))
	content.add_child(UI.option("Send your troops", _auto.bind(p), Roster.healthy(GS.player_party().roster) > 0))
	content.add_child(UI.option("Never mind", func(): refresh()))

# ---------------------------------------------------------------------------
func _build_lord_talk(p: Dictionary) -> void:
	var lid: String = p.lord
	var ld: Dictionary = Data.lords[lid]
	var lr: Dictionary = GS.lords[lid]
	content.add_child(UI.rich("[b]%s:[/b] \"%s\"" % [ld.name, ld.line], 700))
	content.add_child(UI.spacer(4))
	var pl: Dictionary = GS.player
	var faction: String = p.faction
	if pl.faction == "":
		var is_king: bool = ld.get("king", false)
		if pl.renown >= 150 and is_king and lr.relation >= -5:
			content.add_child(UI.option("I wish to pledge myself to you as a vassal.", _pledge.bind(lid)))
		elif is_king:
			content.add_child(UI.rich("[i](You need at least 150 renown to be accepted as a vassal. You have %d.)[/i]" % pl.renown, 700))
		if lr.relation >= -5:
			content.add_child(UI.option("I offer my sword to the %s as a mercenary." % Data.factions[faction].name, _mercenary.bind(lid)))
	elif pl.faction == faction:
		content.add_child(UI.rich("[i]%s greets you as a fellow servant of the %s.[/i]" % [ld.name, Data.factions[faction].name], 700))
		if pl.status == "vassal" and ld.get("king", false):
			content.add_child(UI.option("My liege, I request a fief.", _request_fief.bind(lid)))
	content.add_child(UI.option("What news of the war?", func():
		note = Data.rumors.pick_random()
		page = "talk"
		refresh()))
	content.add_child(UI.option("Farewell.", _leave.bind(p)))

func _mercenary(lid: String) -> void:
	var f: String = Data.lords[lid].faction
	GS.player.faction = f
	GS.player.status = "mercenary"
	GS.player.wars = []
	GS.change_faction_rel(f, 10)
	GS.log_msg("You are now a mercenary in the service of the %s. You will be paid every week." % Data.factions[f].name, Color(0.9, 0.85, 0.5))
	note = "\"Good. We'll pay you well — as long as you kill our enemies.\""
	refresh()

func _pledge(lid: String) -> void:
	var f: String = Data.lords[lid].faction
	GS.player.faction = f
	GS.player.status = "vassal"
	GS.player.wars = []
	GS.change_faction_rel(f, 20)
	GS.change_lord_rel(lid, 10)
	# Grant a village
	var villages := []
	for sid in GS.settlements:
		if GS.settlements[sid].faction == f and Data.settlements[sid].type == "village":
			villages.append(sid)
	if not villages.is_empty():
		var v: String = villages.pick_random()
		GS.settlements[v].owner = "player"
		GS.log_msg("You have been granted the village of %s as your fief." % Data.settlements[v].name, Color(1, 0.9, 0.4))
	# Any settlements you held independently now belong to your new liege's realm
	for sid in GS.settlements:
		if GS.settlements[sid].faction == "player":
			GS.settlements[sid].faction = f
	GS.add_renown(10)
	GS.log_msg("You swore fealty to %s. You are now a vassal of the %s." % [Data.lords[lid].name, Data.factions[f].name], Color(1, 0.9, 0.4))
	note = "\"Rise, %s. Serve me well.\"" % GS.player.name
	refresh()

func _request_fief(lid: String) -> void:
	var f: String = Data.lords[lid].faction
	var owned := 0
	for sid in GS.settlements:
		if GS.settlements[sid].owner == "player":
			owned += 1
	if GS.player.renown < 150 + owned * 150:
		note = "\"You have not yet earned more lands. Win me victories first.\" (Renown needed: %d)" % (150 + owned * 150)
	else:
		var opts := []
		for sid in GS.settlements:
			if GS.settlements[sid].faction == f and Data.settlements[sid].type == "village" and GS.settlements[sid].owner != "player":
				opts.append(sid)
		if opts.is_empty():
			note = "\"I have no lands to spare.\""
		else:
			var v: String = opts.pick_random()
			GS.settlements[v].owner = "player"
			note = "\"Very well. %s is yours.\"" % Data.settlements[v].name
			GS.log_msg("You were granted %s." % Data.settlements[v].name, Color(1, 0.9, 0.4))
	page = "talk"
	refresh()

# ---------------------------------------------------------------------------
func _build_avatar(p: Dictionary) -> void:
	var met: bool = GS.flags.has("met_avatar")
	if not met:
		content.add_child(UI.rich("A giant six-legged flying bison lands in front of you. A bald boy with a blue arrow tattoo hops down.\n\n[b]Aang:[/b] \"Hi! I'm Aang. This is Katara, Sokka, and Toph. And that's Appa! We're trying to end the war. Are you friendly?\"", 700))
	else:
		content.add_child(UI.rich("[b]Aang:[/b] \"Hey, it's you again! " + ["Sokka has a new plan. Again.", "Katara says we need to keep moving.", "Toph keeps calling me Twinkletoes.", "Have you seen a grumpy guy with a ponytail? He keeps following us."].pick_random() + "\"", 700))
	if not met:
		content.add_child(UI.option("\"I fight the Fire Nation too. How can I help?\"", func():
			GS.flags.met_avatar = true
			GS.add_renown(15)
			GS.give_player_xp(300)
			if GS.player.bend != "":
				GS.player.skill_points += 1
				note = "Aang shows you a few tricks from his travels. (+1 skill point, +15 renown)"
			else:
				note = "Sokka gives you some strategy tips, mostly about meat. (+15 renown)"
			refresh()))
	var last: float = GS.flags.get("katara_heal", -999.0)
	if GS.hours - last > 24.0 * 7.0 and Roster.wounded(GS.player_party().roster) > 0:
		content.add_child(UI.option("Ask Katara to heal your wounded", func():
			GS.flags.katara_heal = GS.hours
			Roster.heal_fraction(GS.player_party().roster, 0.7)
			GS.player.hp = GS.max_hp()
			note = "Katara bends water around your wounded. Many of them stand up healed."
			refresh()))
	content.add_child(UI.option("Ask about the Fire Nation", func():
		note = "[b]Sokka:[/b] \"Sozin's Comet comes at the end of summer (%s). If the Fire Lord isn't stopped before then, it's over. Oh, and on the Day of Black Sun (%s), firebenders lose their bending for a few hours. Just saying.\"" % [GS.day_name(GS.COMET_DAY), GS.day_name(GS.ECLIPSE_DAY)]
		refresh()))
	content.add_child(UI.option("Farewell, Avatar.", _leave.bind(p)))
