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
	if p.kind == "pilgrim":
		_build_pilgrim(p)
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
		if o.pos.distance_to(pp.pos) > 10.0 or o.kind == "pilgrim":
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
		if p.faction != GS.player_faction():
			content.add_child(UI.option("Attack them! (this means war with the %s)" % Data.factions[p.faction].name, _confirm_attack.bind(p)))
		content.add_child(UI.option("Leave", _leave.bind(p)))
		return
	var desc := ""
	match p.kind:
		"caravan": desc = "A merchant caravan, guarded by a handful of hired swords. The merchants eye you nervously."
		"villager": desc = "Villagers on their way to market with carts of produce."
		"bandit": desc = "A ragged band who seem unsure whether to fight you."
	if p.faction == "red_lanterns":
		desc = "\"We take from the tax barges and give to the Lower Ring. If that offends you, say so now.\" — a woman with a red lantern tattooed on her wrist."
	content.add_child(UI.rich(desc, 700))
	content.add_child(UI.option("Attack them!", _confirm_attack.bind(p)))
	content.add_child(UI.option("Leave them be", _leave.bind(p)))

func _confirm_attack(p: Dictionary) -> void:
	UI.clear(content)
	var f: String = p.faction
	var warn := "Attacking them will make you an enemy of the %s." % Data.factions.get(f, Data.factions.neutral).name
	if f == "red_lanterns":
		GS.change_faction_rel("red_lanterns", -50)
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
	# A Fire Nation noble you have offended may demand satisfaction
	if _agni_kai_possible(lid) and lr.relation <= -25 and GS.standing_rank() >= 2 and not GS.flags.has("agni_kai_" + lid):
		_build_agni_kai_challenge(p, lid, true)
		return
	if pl.faction == "":
		var is_king: bool = GS.is_king(lid)
		if pl.renown >= 150 and is_king and lr.relation >= -5:
			content.add_child(UI.option("I wish to pledge myself to you as a vassal.", _pledge.bind(lid)))
		elif is_king:
			content.add_child(UI.rich("[i](You need at least 150 renown to be accepted as a vassal. You have %d.)[/i]" % pl.renown, 700))
		if lr.relation >= -5:
			content.add_child(UI.option("I offer my sword to the %s as a mercenary." % Data.factions[faction].name, _mercenary.bind(lid)))
	elif pl.faction == faction:
		content.add_child(UI.rich("[i]%s greets you as a fellow servant of the %s.[/i]" % [ld.name, Data.factions[faction].name], 700))
		if pl.status == "vassal" and GS.is_king(lid):
			content.add_child(UI.option("My liege, I request a fief.", _request_fief.bind(lid)))
	if not GS.at_war(GS.player_faction(), faction) and lr.relation >= -10:
		content.add_child(UI.option("Do you have any tasks for me?", func():
			var q: Dictionary = load("res://scripts/core/quests.gd").generate_lord(lid)
			if q.is_empty():
				note = "\"Not at the moment.\""
				page = "talk"
				refresh()
				return
			UI.clear(content)
			content.add_child(UI.rich("[b]%s[/b]\n\n%s" % [q.title, q.desc], 700))
			content.add_child(UI.option("I accept.", func():
				load("res://scripts/core/quests.gd").accept(q)
				note = "\"Good. Don't disappoint me.\""
				page = "talk"
				refresh()))
			content.add_child(UI.option("Not now.", func():
				page = "talk"
				refresh()))))
	content.add_child(UI.option("Tell me about yourself.", func():
		note = "[i]%s[/i]" % (ld.get("bio_sandbox", ld.get("bio", "")) if GS.flags.get("era", "quiet") != "quiet" else ld.get("bio", ""))
		page = "talk"
		refresh()))
	if _agni_kai_possible(lid) and GS.day() - int(GS.flags.get("agni_kai_" + lid, -999)) > 30:
		if GS.standing_rank() >= 2:
			content.add_child(UI.option("I challenge you to an Agni Kai.", _build_agni_kai_challenge.bind(p, lid, false)))
		else:
			content.add_child(UI.rich("[i](A Fire Nation noble will only accept an Agni Kai from someone of Gentry standing or higher. You are %s.)[/i]" % GS.standing_name(), 700))
	content.add_child(UI.option("What news of the war?", func():
		note = Data.rumor()
		page = "talk"
		refresh()))
	content.add_child(UI.option("Farewell.", _leave.bind(p)))

## Agni Kai are fought between firebenders; a non-bender needs a champion.
func _agni_kai_possible(lid: String) -> bool:
	var ld: Dictionary = Data.lords[lid]
	if ld.faction != "fire_nation" or ld.bend != "fire" or GS.is_king(lid):
		return false
	return GS.player.bend == "fire" or GS.agni_kai_champion() != ""

func _build_agni_kai_challenge(p: Dictionary, lid: String, they_challenge: bool) -> void:
	var ld: Dictionary = Data.lords[lid]
	UI.clear(content)
	if they_challenge:
		content.add_child(UI.rich("[b]%s:[/b] \"You have insulted my house once too often. I demand an Agni Kai — at noon, before witnesses. Unless you are a coward.\"" % ld.name, 700))
	else:
		content.add_child(UI.rich("[b]%s:[/b] \"An Agni Kai? Very well. At noon, before witnesses. Fire decides, and the matter is closed whatever it decides.\"" % ld.name, 700))
	if GS.player.bend == "fire":
		content.add_child(UI.option("Fight the Agni Kai yourself", func():
			GS.player.inside = ""
			GS.start_duel(lid), GS.player.hp > GS.max_hp() * 0.4))
		if GS.player.hp <= GS.max_hp() * 0.4:
			content.add_child(UI.rich(UI.color_text("You are too badly hurt to fight a duel.", UI.RED), 700))
	var champ := GS.agni_kai_champion()
	if champ != "":
		var cname: String = Data.companions[champ].get("short", Data.companions[champ].name)
		content.add_child(UI.option("Name %s as your champion" % cname, func():
			var won := GS.champion_duel(lid, champ)
			note = GS.last_battle_result.lines[0]
			GS.last_battle_result = {}
			if not won:
				GS.companion_state(champ).wounded = true
			page = "talk"
			refresh()))
	content.add_child(UI.option("Refuse" + (" (dishonourable)" if they_challenge else ""), func():
		if they_challenge:
			GS.flags["agni_kai_" + lid] = GS.day()
			GS.player.honor = int(GS.player.get("honor", 0)) - 2
			GS.add_renown(-5)
			GS.change_faction_rel("fire_nation", -3)
			load("res://scripts/story/story.gd").react("refuse_duel")
			note = "%s turns away in contempt. Word of your refusal will travel through every noble house in Caldera. (-2 honour)" % ld.name
		else:
			note = "\"Then do not waste my time with challenges.\""
		page = "talk"
		refresh()))

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
	GS.raise_standing("gentry")
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
func _build_pilgrim(p: Dictionary) -> void:
	var met: bool = GS.flags.has("met_pilgrims")
	if not met:
		content.add_child(UI.rich("A sky bison settles in the grass beside your column, and a dozen novices tumble off its saddle. An elderly nun with blue arrows on her hands bows to you.\n\n[b]Pilgrim:[/b] \"We fly between the temples and wherever people are hungry. You look like you have walked a long way. Sit, if you like. We have fruit.\"", 700))
	else:
		content.add_child(UI.rich("[b]Pilgrim:[/b] \"" + [
			"The novices have named the bison after you. It is meant as a compliment, mostly.",
			"We carried forty refugees out of the Ember Coast last week. The Admiralty's ships watched us go and did nothing. That will not last.",
			"Abbess Tsering asks after you. She says you have the face of someone who is about to make a large decision.",
			"Violence is always a choice. So is lunch. We have chosen lunch."].pick_random() + "\"", 700))
	if not met:
		content.add_child(UI.option("Sit with them and share news of the road", func():
			GS.flags.met_pilgrims = true
			GS.add_renown(5)
			GS.give_player_xp(150)
			GS.change_faction_rel("air_nomads", 10)
			note = "You eat moon peaches and trade news for an hour. The novices are delighted by your boots. (+10 Air Nomad relation)"
			refresh()))
	var last: float = GS.flags.get("pilgrim_heal", -999.0)
	if GS.hours - last > 24.0 * 5.0 and (Roster.wounded(GS.player_party().roster) > 0 or GS.player.hp < GS.max_hp()):
		content.add_child(UI.option("Ask the monks to tend your wounded", func():
			GS.flags.pilgrim_heal = GS.hours
			Roster.heal_fraction(GS.player_party().roster, 0.6)
			GS.player.hp = GS.max_hp()
			note = "The monks move among your wounded with herbs, clean water and a great deal of patience. Many of them are walking by evening. They will not take payment."
			refresh()))
	content.add_child(UI.option("Ask what the sky has in store", func():
		var e := GS.next_cosmic()
		if e.is_empty():
			note = "[b]Pilgrim:[/b] \"The sages see no eclipses and no comets for a long while. Only weather. Weather is enough.\""
		else:
			var what: String = {"solar": "the sun will go dark", "lunar": "the full moon will be eclipsed", "comet": "a comet will cross the sky"}[e.kind]
			note = "[b]Pilgrim:[/b] \"The Crescent Island sages say %s on %s. They are rarely wrong about the sky. People are another matter.\"" % [what, GS.day_name(e.day)]
		refresh()))
	content.add_child(UI.option("Ask about the wars", func():
		note = "[b]Pilgrim:[/b] \"" + [
			"The Fire Nation is hungry and the Earth Kingdom is proud. Hunger and pride make long wars.",
			"Omashu fed its own people first and Ba Sing Se called it treason. Both are right. That is the trouble with this war.",
			"The South raids the Fire Navy's supply ships. The supply ships carry rice to soldiers who carry fire to villages. Follow anything far enough and it is all one circle.",
			"Eleven years ago an Avatar drowned trying to make a peace. We are still waiting for someone to finish the sentence." if GS.flags.get("era", "quiet") == "quiet" else "The Avatar cannot be everywhere. That is why the rest of us have to be somewhere."].pick_random() + "\""
		refresh()))
	content.add_child(UI.option("Go in peace.", _leave.bind(p)))
