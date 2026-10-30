extends "res://scripts/ui/window_base.gd"
## Mount & Blade style text menu for a settlement.

const Roster = preload("res://scripts/core/roster.gd")
const Story = preload("res://scripts/story/story.gd")
const Economy = preload("res://scripts/core/economy.gd")
const Quests = preload("res://scripts/core/quests.gd")
const AutoResolve = preload("res://scripts/core/auto_resolve.gd")
const AvatarSys = preload("res://scripts/core/avatar.gd")
const BendingWork = preload("res://scripts/core/bending_work.gd")
const Fealty = preload("res://scripts/core/fealty.gd")

var sid := ""
var map
var page := "main"
var note := ""

func _init() -> void:
	window_size = Vector2(820, 600)

func build() -> void:
	var d: Dictionary = Data.settlements[sid]
	var s: Dictionary = GS.settlements[sid]
	set_title(d.name)
	var fd: Dictionary = Data.factions.get(s.faction, Data.factions.neutral)
	var header := "[b]%s[/b] of the %s" % [d.type.capitalize(), fd.name]
	if s.faction == sid:
		header = "[b]%s[/b] — governs itself, under %s" % [fd.get("kind", "Community"), fd.get("head", "its elders")]
	if s.owner == "player":
		header += " — [color=#2a6a2a]your fief[/color]"
	elif Data.lords.has(s.owner):
		header += " — held by %s" % Data.lords[s.owner].name
	var ov := Fealty.overlord(s.faction)
	if ov != "":
		header += "\nPays tribute to %s" % ("you" if ov == "player" else "the " + Data.factions[ov].name)
	if not d.type in ["ruin", "temple"]:
		header += "\nProsperity: %d" % int(s.prosperity)
		if d.type != "village":
			header += "   Garrison: %d" % Roster.total(s.garrison)
		header += "   Your relation: %d" % s.relation
	content.add_child(UI.rich(header, 760))
	content.add_child(UI.rich("[i]%s[/i]" % d.desc, 760))
	if s.looted_until > GS.hours:
		content.add_child(UI.rich(UI.color_text("The village has been raided and lies in ashes.", UI.RED), 760))
	if not s.siege.is_empty():
		var sf: String = s.siege.get("faction", "")
		content.add_child(UI.rich(UI.color_text("Under siege by the %s!" % Data.factions.get(sf, Data.factions.neutral).name, UI.RED), 760))
	if AvatarSys.present_at(sid):
		content.add_child(UI.rich(UI.color_text("%s is here. People are queueing in the street to speak with %s." % [AvatarSys.display_name().capitalize(), AvatarSys.pronouns()[1]], Color(0.3, 0.45, 0.75)), 760))
	if note != "":
		content.add_child(UI.rich(note, 760))
	content.add_child(UI.sep())
	var body := UI.scroll(250)
	content.add_child(body)
	var opts := UI.vbox(5)
	opts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(opts)
	match page:
		"main": _build_main(opts)
		"tavern": _build_tavern(opts)
		"hall": _build_hall(opts)
		"recruit": _build_recruit(opts)
		"arena": _build_arena(opts)
		"council": _build_council(opts)

func _go(p: String) -> void:
	page = p
	note = ""
	refresh()

func _open(w: Control) -> void:
	map.open_window(w)
	w.tree_exited.connect(func():
		if is_inside_tree():
			refresh())

# ---------------------------------------------------------------------------
func _build_main(o: VBoxContainer) -> void:
	var d: Dictionary = Data.settlements[sid]
	var s: Dictionary = GS.settlements[sid]
	var pf := GS.player_faction()
	var hostile := GS.at_war(s.faction, pf)
	# Story beats available here (quests, companions, the logbook)
	if not hostile or d.type in ["ruin", "temple"]:
		for so in Story.settlement_options(sid):
			o.add_child(UI.option("★ " + so.text, _story_option.bind(so)))
	# The Avatar: rarely here, hard to reach even then
	if AvatarSys.present_at(sid) and not AvatarSys.hostile():
		var tried: bool = int(AvatarSys.state().get("audience_day", -99)) == GS.day()
		o.add_child(UI.option("✦ Seek an audience with %s (%d%% chance today)" % [AvatarSys.display_name(), int(AvatarSys.audience_chance() * 100)], _seek_avatar, not tried))
	var A: Dictionary = AvatarSys.state()
	if sid == A.get("home", "") and A.get("intel", false) and not A.get("hostage", false) and AvatarSys.stage() != "child":
		o.add_child(UI.option("✦ Find the house of %s" % A.get("loved", {}).get("name", "the one the Avatar loves"), _story_option.bind({"dlg": "av_hostage_take", "text": ""})))
	if d.type == "ruin":
		_build_ruin(o)
		return
	if d.type == "temple":
		_build_temple(o)
		return
	if s.siege.get("leader", "") == "player":
		_build_player_siege(o)
		return
	if hostile:
		if d.type == "village":
			if s.looted_until < GS.hours:
				o.add_child(UI.option("Raid the village (dishonourable)", _raid))
			if s.owner != "player" and GS.party_size() >= 10:
				o.add_child(UI.option("Take the village and hold it as your own", _take_village))
				if BendingWork.blocker("scorch", sid) == "":
					o.add_child(UI.option("Scorch their fields with firebending (cruel; infamy)", func():
						note = BendingWork.perform("scorch", sid)
						refresh()))
			o.add_child(UI.option("Leave", close))
		else:
			o.add_child(UI.rich("The gates are shut against you. Archers watch you from the walls.", 740))
			o.add_child(UI.option("Lay siege to %s" % d.name, _begin_siege, GS.party_size() >= 10))
			if GS.party_size() < 10:
				o.add_child(UI.rich("[i](You need at least 10 men to besiege.)[/i]", 740))
			o.add_child(UI.option("Leave", close))
		return
	# Friendly or neutral settlement
	if s.siege.is_empty() and map != null and map.has_method("open_settlement"):
		o.add_child(UI.option("Walk around %s" % d.name, _walk))
	if not s.siege.is_empty() and GS.at_war(s.siege.faction, s.faction) and GS.at_war(s.siege.faction, pf):
		o.add_child(UI.option("Break the siege! Attack the besiegers", _defend))
	for q in Quests.deliverable_at(sid):
		o.add_child(UI.option("Deliver: %s" % q.title, func():
			if Quests.try_deliver(sid):
				note = UI.color_text("Delivered!", UI.GREEN)
			else:
				note = UI.color_text("You don't have what was asked for yet.", UI.RED)
			refresh()))
	if sid == "ba_sing_se":
		_build_rings(o)
		return
	match d.type:
		"town":
			o.add_child(UI.option("Visit the marketplace", func(): _open(_mk("res://scripts/ui/trade_window.gd"))))
			o.add_child(UI.option("Visit the weaponsmith and armourer", func(): _open(_mk("res://scripts/ui/shop_window.gd")), s.looted_until < GS.hours))
			o.add_child(UI.option("Go to the tavern", func(): _go("tavern")))
			o.add_child(UI.option("Go to the lord's hall", func(): _go("hall")))
			o.add_child(UI.option("Speak with the guild master (work)", _ask_work))
			if sid == "gaoling":
				o.add_child(UI.option("Visit the Stone Pit", func(): _go("arena")))
			if sid == "southern_tribe":
				o.add_child(UI.option("Go to the council hall", func(): _go("council")))
			if s.faction == "earth_kingdom" and not GS.player.get("permits", {}).has("earth_kingdom"):
				o.add_child(UI.option("Apply for an Earth Kingdom trade permit (250 gold, needs Citizen standing)", func():
					GS.add_gold(-250)
					if not GS.player.has("permits"):
						GS.player.permits = {}
					GS.player.permits["earth_kingdom"] = true
					note = "After four forms, two seals and a clerk who sighs at you, the permit is yours. Earth Kingdom markets will deal with you at better rates."
					refresh(), GS.player.gold >= 250 and GS.standing_rank() >= 1))
		"castle":
			o.add_child(UI.option("Go to the lord's hall", func(): _go("hall")))
			o.add_child(UI.option("Speak with the castle steward (work)", _ask_work))
		"village":
			if s.looted_until < GS.hours:
				o.add_child(UI.option("Recruit volunteers (%d available)" % s.volunteers, func(): _go("recruit")))
				o.add_child(UI.option("Buy supplies from the villagers", func(): _open(_mk("res://scripts/ui/trade_window.gd"))))
			o.add_child(UI.option("Speak with the village elder (work)", _ask_work))
			_tribute_options(o)
	if s.owner == "player" and d.type != "village":
		o.add_child(UI.option("Manage the garrison", func(): _open(_mk("res://scripts/ui/garrison_window.gd"))))
	_work_option(o)
	o.add_child(UI.option("Rest here for a day (heal faster)", _rest.bind(24.0)))
	o.add_child(UI.option("Wait here until healed", _rest.bind(-2.0), Roster.wounded(GS.player_party().roster) > 0 or GS.player.hp < GS.max_hp()))
	o.add_child(UI.option("Leave", close))

## Bending at work (element expansions): offered wherever some job fits.
func _work_option(o: VBoxContainer) -> void:
	var n := 0
	for id in BendingWork.available(sid):
		if BendingWork.blocker(id, sid) == "":
			n += 1
	if not BendingWork.available(sid).is_empty():
		o.add_child(UI.option("Put bending to work (%d job%s here)" % [n, "" if n == 1 else "s"], func():
			var w = load("res://scripts/ui/bending_work_window.gd").new()
			w.sid = sid
			_open(w)))

func _seek_avatar() -> void:
	AvatarSys.state().audience_day = GS.day()
	if randf() < AvatarSys.audience_chance():
		_story_option({"dlg": "av_audience", "text": ""})
	else:
		note = ["One of the Avatar's companions, a polite woman with a very large staff, says the Avatar is in meditation and cannot be disturbed. Come back tomorrow.",
			"You wait four hours. A monk brings you tea, apologises, and says the Avatar was called away. You have the strong impression they are still in the building.",
			"The queue does not move. By evening you are told the Avatar has already left, by a door nobody else seems to know about."].pick_random()
		refresh()

## Enter the walkable version of this settlement.
func _walk() -> void:
	GS.player.inside = sid
	GS.flags.town_sid = sid
	GS.save_game(GS.AUTOSAVE_PATH)
	get_tree().change_scene_to_file("res://scenes/town.tscn")

func _story_option(so: Dictionary) -> void:
	if so.has("once"):
		Story.set_flag("opt_" + so.dlg, true)
	GS.player.inside = sid
	var dw = map.open_dialogue(so.dlg)
	if dw == null:
		return
	dw.tree_exited.connect(func():
		if is_inside_tree() and not is_queued_for_deletion():
			refresh())

func _mk(path: String) -> Control:
	var w = load(path).new()
	w.sid = sid
	return w

func _rest(hours: float) -> void:
	GS.player.inside = sid
	if hours < 0.0:
		# estimate time until healed
		var frac := 0.12 + GS.skill("healing") * 0.03
		hours = clampf(24.0 * (1.0 / maxf(0.1, frac * 1.6)), 24.0, 24.0 * 7.0)
	map.start_waiting(hours)
	GS.player.inside = sid
	close()

func _ask_work() -> void:
	var q := Quests.generate(sid)
	if Quests.has_quest_from(sid):
		note = "\"You already have a task from us. Finish it first.\""
		refresh()
		return
	if q.is_empty():
		note = "\"Nothing needs doing right now. Come back in a few days.\""
		refresh()
		return
	UI.clear(content)
	content.add_child(UI.rich("[b]%s[/b]\n\n%s" % [q.title, q.desc], 760))
	content.add_child(UI.sep())
	content.add_child(UI.option("Accept", func():
		Quests.accept(q)
		note = UI.color_text("Quest accepted: " + q.title, UI.GREEN)
		refresh()))
	content.add_child(UI.option("Decline", func(): refresh()))

func _begin_siege() -> void:
	var s: Dictionary = GS.settlements[sid]
	s.siege = {"faction": GS.player_faction(), "leader": "player", "hours": 0.0}
	GS.player.siege_start = GS.hours
	GS.log_msg("You have laid siege to %s." % Data.settlements[sid].name, Color(1, 0.7, 0.4))
	refresh()

func _defend() -> void:
	var s: Dictionary = GS.settlements[sid]
	var enemies := []
	for id in GS.parties:
		if GS.parties[id].get("besieging", "") == sid:
			enemies.append(id)
	if enemies.is_empty():
		s.siege = {}
		note = "The besiegers have already gone."
		refresh()
		return
	GS.start_battle(enemies, [], sid, false)

func _raid() -> void:
	var s: Dictionary = GS.settlements[sid]
	var d: Dictionary = Data.settlements[sid]
	# Villagers put up a token fight
	var militia := []
	Roster.add(militia, Data.culture_recruit.get(d.culture, "ek_peasant"), 6 + randi() % 8)
	var pp: Dictionary = GS.player_party()
	var my = GS.sim.party_power(pp)
	var lost := 0
	if my < Roster.power(militia) * 1.2:
		for i in 2:
			var tid := Roster.random_troop(pp.roster)
			if tid != "":
				Roster.wound(pp.roster, tid, 1)
				lost += 1
	s.looted_until = GS.hours + 24.0 * 6.0
	s.prosperity = maxf(5.0, s.prosperity - 20.0)
	s.relation = -40
	s.volunteers = 0
	var gold := 150 + int(s.prosperity * 4)
	GS.add_gold(gold)
	for g in Data.settlements[sid].produces:
		GS.add_good(g, 2 + randi() % 3)
	GS.player.honor = GS.player.get("honor", 0) - 5
	GS.change_faction_rel(s.faction, -10)
	Fealty.protect(s.faction, GS.player_faction())
	AvatarSys.add_infamy(25, d.pos, "raiding " + d.name)
	Story.react("raid")
	# Mixed Strait Isles villages: burning them angers both nations
	var kin: String = {"earth": "earth_kingdom", "fire": "fire_nation", "north": "northern_water", "south": "southern_water", "omashu": "omashu"}.get(d.culture, "")
	if kin != "" and Data.region_of(kin) != Data.region_of(s.faction):
		GS.change_faction_rel(kin, -6)
		GS.log_msg("The village's families were %s. Their kin will hear of this." % Data.factions[kin].name, Color(1, 0.5, 0.35))
	if Data.lords.has(s.owner):
		GS.change_lord_rel(s.owner, -15)
	GS.log_msg("You raided %s, taking %d gold and supplies." % [d.name, gold], Color(1, 0.6, 0.3))
	Quests.on_raid(sid)
	note = "Your men loot the village. Smoke rises behind you."
	refresh()

## A community's elders, asked for tribute or released from it.
func _tribute_options(o: VBoxContainer) -> void:
	var s: Dictionary = GS.settlements[sid]
	if not Fealty.is_community(s.faction) or GS.player_faction() != "player":
		return
	var ov := Fealty.overlord(s.faction)
	if ov == "player":
		o.add_child(UI.option("Release %s from its tribute to you" % Data.settlements[sid].name, func():
			Fealty.release(s.faction)
			note = "The elders thank you, carefully, in case it is a test."
			refresh()))
		return
	var asked: bool = GS.day() - int(GS.flags.get("demand_day_" + s.faction, -999)) < 30
	var label := "Ask the elders to pay tribute to you, for your protection"
	if ov != "":
		label += " (they pay the %s; it will take offence)" % Data.factions[ov].short
	o.add_child(UI.option(label, func():
		note = Fealty.player_demand(s.faction)
		refresh(), not asked and GS.party_size() >= 10))

## Hold a village by force: its militia fights, and then it is yours.
func _take_village() -> void:
	var s: Dictionary = GS.settlements[sid]
	var d: Dictionary = Data.settlements[sid]
	var militia := []
	Roster.add(militia, Data.culture_recruit.get(d.get("troops_culture", d.culture), "ek_peasant"), 8 + randi() % 10)
	var pp: Dictionary = GS.player_party()
	if GS.sim.party_power(pp) < Roster.power(militia) * 1.5:
		for i in 3:
			var tid := Roster.random_troop(pp.roster)
			if tid != "":
				Roster.wound(pp.roster, tid, 1)
	var old: String = s.faction
	GS.sim.capture_settlement(sid, GS.player_faction(), "player")
	s.prosperity = maxf(5.0, s.prosperity - 10.0)
	s.relation = mini(int(s.relation), -20)
	GS.change_faction_rel(old, -25)
	AvatarSys.add_infamy(15, d.pos, "seizing " + d.name)
	note = "The village militia breaks. By nightfall your banner hangs from the elder's house, and nobody in the village will look at it."
	refresh()

# ---------------------------------------------------------------------------
func _build_player_siege(o: VBoxContainer) -> void:
	var s: Dictionary = GS.settlements[sid]
	var waited: float = GS.hours - GS.player.get("siege_start", GS.hours)
	var ready := waited >= 12.0
	o.add_child(UI.rich("Your camp surrounds the walls. Siege ladders: %s" % ("ready" if ready else "%d hours until ready" % int(12.0 - waited)), 740))
	o.add_child(UI.rich("Defenders: %d in the garrison." % Roster.total(s.garrison), 740))
	o.add_child(UI.option("Wait and prepare (6 hours)", func():
		GS.player.inside = ""
		map.start_waiting(6.0)
		GS.player.siege_return = sid
		close()))
	o.add_child(UI.option("Assault the walls!", _assault, ready))
	o.add_child(UI.option("Order your troops to assault without you", _assault_auto, ready and Roster.healthy(GS.player_party().roster) > 0))
	o.add_child(UI.option("Lift the siege", func():
		s.siege = {}
		GS.log_msg("You lifted the siege of %s." % Data.settlements[sid].name)
		close()))

func _defenders_inside() -> Array:
	var out := []
	var pos: Vector2 = Data.settlements[sid].pos
	for id in GS.parties:
		var p: Dictionary = GS.parties[id]
		if id != "player" and p.kind == "lord" and p.pos.distance_to(pos) < 8.0 and GS.parties_hostile(p, GS.player_party()):
			out.append(id)
	return out

func _assault() -> void:
	GS.start_battle(_defenders_inside(), [], sid, true)

func _assault_auto() -> void:
	GS.auto_resolve_player(_defenders_inside(), [], sid, true)
	var rw = load("res://scripts/ui/result_window.gd").new()
	rw.result = GS.last_battle_result
	GS.last_battle_result = {}
	map.open_window(rw)
	close()

# ---------------------------------------------------------------------------
func _build_ruin(o: VBoxContainer) -> void:
	var s: Dictionary = GS.settlements[sid]
	if sid == "red_lantern_den":
		o.add_child(UI.rich("Red paper lanterns sway over the reeds. A boat that was not there a moment ago drifts across your path.", 740))
		if not GS.at_war("red_lanterns", GS.player_faction()):
			o.add_child(UI.option("Ask to speak with the Brotherhood", func():
				note = "[b]Elder Sister Lan:[/b] \"The tax barges carry rice from starving villages to the Upper Ring's granaries. We carry it back down. If you think that makes us thieves, you have never been hungry in Ba Sing Se.\""
				if GS.player.get("faction", "") == "earth_kingdom":
					note = "[b]Elder Sister Lan:[/b] \"You wear the Queen's colours. Leave while the reeds still like you.\""
				refresh()))
		o.add_child(UI.option("Leave", close))
		return
	if not s.explored:
		o.add_child(UI.option("Explore the ruins", _explore))
	else:
		o.add_child(UI.rich("You have already explored this place.", 740))
	o.add_child(UI.option("Leave", close))

# ---------------------------------------------------------------------------
# Ba Sing Se: three rings, three sets of gates, one Censorate
# ---------------------------------------------------------------------------
func _ring_access(ring: String) -> bool:
	match ring:
		"middle":
			# The Censorate remembers a vault thief; papers and bribes stop working
			if GS.flags.get("censor_enemy", false) and not GS.flags.get("wu_defeated", false) and GS.settlements[sid].owner != "player":
				return GS.standing_rank() >= 2
			return GS.standing_rank() >= 1 or GS.player.get("permits", {}).has("middle_ring")
		"upper": return GS.standing_rank() >= 2 or GS.flags.get("upper_invite", false) or GS.lords.get("hualing", {}).get("relation", 0) >= 10
	return true

func _build_rings(o: VBoxContainer) -> void:
	var s: Dictionary = GS.settlements[sid]
	o.add_child(UI.rich("[b]The Lower Ring[/b] — refugees, labourers and the smell of a million cooking fires. Nobody here asks for papers.", 740))
	o.add_child(UI.option("Go to a Lower Ring tavern", func(): _go("tavern")))
	o.add_child(UI.option("Visit the labour hall (recruit Lower Ring volunteers: %d)" % s.volunteers, func(): _go("recruit"), s.volunteers > 0))
	o.add_child(UI.option("Rest in a Lower Ring boarding house (a day)", _rest.bind(24.0)))
	o.add_child(UI.spacer(4))
	if _ring_access("middle"):
		o.add_child(UI.rich("[b]The Middle Ring[/b] — merchants, scholars and the civil examination halls. The gate guard checks your papers and waves you through.", 740))
		o.add_child(UI.option("Visit the Middle Ring market", func(): _open(_mk("res://scripts/ui/trade_window.gd"))))
		o.add_child(UI.option("Speak with the merchants' guild (work)", _ask_work))
		if not GS.player.get("permits", {}).has("earth_kingdom"):
			o.add_child(UI.option("Apply for an Earth Kingdom trade permit (250 gold)", func():
				GS.add_gold(-250)
				if not GS.player.has("permits"):
					GS.player.permits = {}
				GS.player.permits["earth_kingdom"] = true
				note = "Four forms, two seals and one sighing clerk later, the permit is yours."
				refresh(), GS.player.gold >= 250))
	else:
		o.add_child(UI.rich("[b]The Middle Ring gate[/b] — a guard holds out a hand for papers you do not have.", 740))
		o.add_child(UI.option("Buy Middle Ring travel papers (300 gold)", func():
			GS.add_gold(-300)
			if not GS.player.has("permits"):
				GS.player.permits = {}
			GS.player.permits["middle_ring"] = true
			note = "The clerk stamps your papers with the patience of a man who has stamped a hundred thousand of them. You may pass the Middle Ring gate."
			refresh(), GS.player.gold >= 300 and not GS.flags.get("censor_enemy", false)))
		o.add_child(UI.option("Bribe the gate guard (60 gold — the Censorate may notice)", _bribe_gate))
		if GS.flags.get("censor_enemy", false):
			o.add_child(UI.rich("[i]The clerk's ledger has your description in it, underlined twice. Until the Grand Secretary falls, only Gentry standing will get you through.[/i]", 740))
	o.add_child(UI.spacer(4))
	if _ring_access("upper"):
		o.add_child(UI.rich("[b]The Upper Ring[/b] — gardens, silent streets and the palace. Servants bow to you as if you belong here.", 740))
		o.add_child(UI.option("Visit the Upper Ring armourers", func(): _open(_mk("res://scripts/ui/shop_window.gd")), s.looted_until < GS.hours))
		o.add_child(UI.option("Request an audience at the palace", func(): _go("hall")))
	else:
		o.add_child(UI.rich("[b]The Upper Ring[/b] is closed to you. [i](Requires Gentry standing or an invitation. You are %s.)[/i]" % GS.standing_name(), 740))
	if s.owner == "player":
		o.add_child(UI.option("Manage the garrison", func(): _open(_mk("res://scripts/ui/garrison_window.gd"))))
	o.add_child(UI.option("Leave the city", close))

func _bribe_gate() -> void:
	if GS.player.gold < 60:
		note = UI.color_text("You can't afford it.", UI.RED)
	elif randf() < 0.25 or GS.flags.get("censor_enemy", false):
		GS.add_gold(-60)
		GS.change_faction_rel("earth_kingdom", -5)
		GS.change_lord_rel("shu_fan", -5)
		note = "The guard takes your coin, and a man in a long slate-grey robe takes your name. You are escorted back to the Lower Ring without a word. (Censorate: -5)"
	else:
		GS.add_gold(-60)
		GS.flags["bsse_pass_day"] = GS.day()
		note = "The coin disappears into a sleeve. The guard looks at the sky while you walk past him."
		if not GS.player.has("permits"):
			GS.player.permits = {}
		GS.player.permits["middle_ring"] = true
	refresh()

# ---------------------------------------------------------------------------
# The Southern council: anyone may speak; few are listened to
# ---------------------------------------------------------------------------
func _build_council(o: VBoxContainer) -> void:
	var rel := int(GS.player.get("faction_rel", {}).get("southern_water", 0))
	o.add_child(UI.rich("The council hall is a ring of whalebone benches around a fire. Chief Siqiniq sits on the same bench as everyone else. Elder Malik is speaking, slowly; Raider-Captain Qannik is interrupting him, quickly.", 740))
	var last := int(GS.flags.get("council_day", -999))
	if rel < 15 and GS.standing_rank() < 2:
		o.add_child(UI.rich("[i]You may sit and listen, but the council will not hear a stranger's motion. (Needs Southern relation 15 or Gentry standing.)[/i]", 740))
	elif GS.day() - last < 30:
		o.add_child(UI.rich("[i]You spoke here recently. The council is still arguing about the last thing you said.[/i]", 740))
	else:
		for k in Data.KINGDOMS:
			if k == "southern_water":
				continue
			if GS.at_war("southern_water", k):
				o.add_child(UI.option("Argue for peace with the %s" % Data.factions[k].name, _council_motion.bind(k, "peace")))
			elif k == "fire_nation" or GS.at_war(k, GS.player_faction()):
				o.add_child(UI.option("Argue for war against the %s" % Data.factions[k].name, _council_motion.bind(k, "war")))
	o.add_child(UI.option("Back", func(): _go("main")))

func _council_motion(k: String, motion: String) -> void:
	GS.flags.council_day = GS.day()
	var rel := float(GS.player.get("faction_rel", {}).get("southern_water", 0))
	var chance := clampf(0.2 + GS.attr("vit") * 0.015 + GS.skill("leadership") * 0.03 + rel / 250.0 + GS.player.renown / 2500.0, 0.05, 0.85)
	if randf() < chance:
		if motion == "peace":
			GS.make_peace("southern_water", k)
			GS.change_lord_rel("malik", 10)
			GS.change_lord_rel("qannik", -15)
			note = "The vote is close, and Qannik walks out before it is counted. The South sends envoys to the %s. Elder Malik catches your sleeve on the way out: \"Thank you. That was the easy part.\"" % Data.factions[k].name
		else:
			GS.declare_war("southern_water", k)
			GS.change_lord_rel("qannik", 10)
			GS.change_lord_rel("malik", -10)
			note = "The hall roars. Qannik claps you on the back hard enough to bruise. Elder Malik does not look at you."
		GS.add_renown(10)
	else:
		note = "You speak well, and the council listens politely, and then votes the other way. Chief Siqiniq gives you a small nod: not today."
	refresh()

func _build_temple(o: VBoxContainer) -> void:
	var d: Dictionary = Data.settlements[sid]
	o.add_child(UI.rich("Wind-chimes sound from every balcony. Novices race sky bison calves across a terrace while refugees from three wars queue for soup. %s greets you at the gate with a bow and no questions." % d.get("abbot", "The abbot"), 740))
	if map != null and map.has_method("open_settlement"):
		o.add_child(UI.option("Walk around %s" % d.name, _walk))
	o.add_child(UI.option("Rest in the temple (free; the monks tend your wounded)", func():
		Roster.heal_fraction(GS.player_party().roster, 0.5)
		GS.player.hp = GS.max_hp()
		_rest(24.0)))
	o.add_child(UI.option("Buy supplies from the temple stores", func(): _open(_mk("res://scripts/ui/trade_window.gd"))))
	_work_option(o)
	o.add_child(UI.option("Donate to the refugees (100 gold)", func():
		GS.add_gold(-100)
		GS.change_faction_rel("air_nomads", 3)
		Story.react("donate")
		GS.player.honor = int(GS.player.get("honor", 0)) + 1
		GS.add_renown(2)
		note = "The abbot accepts the gold for the refugees' kitchens, and thanks you without making a speech about it. (+1 honour)"
		refresh(), GS.player.gold >= 100))
	o.add_child(UI.option("Ask %s about the Avatar" % d.get("abbot", "the abbot"), func():
		if AvatarSys.era() != "quiet" or AvatarSys.known():
			note = "[b]%s:[/b] \"%s\"" % [d.get("abbot", "The abbot"), [
				"%s stayed with us for three days last year and spent two of them asleep. The Avatar's body is still a body. People forget." % AvatarSys.display_name().capitalize(),
				"You want to find the Avatar? Everyone does. The Avatar is on a mountain with a teacher, or in a council hall, or in a ditch helping someone's ox out of it. Pray you never need them badly enough to be found.",
				"The Avatar does not belong to us, though people think so. The Avatar belongs to the balance. Sometimes the balance is a treaty. Sometimes it is a warlord who needs to be stopped."].pick_random()]
			refresh()
			return
		note = "[b]%s:[/b] \"%s\"" % [d.get("abbot", "The abbot"), [
			"The Avatar we lost at sea stayed here once, the winter before the talks. They laughed at our novices' jokes even when the jokes were bad. That is what I remember. Not the Avatar. The laugh.",
			"Somewhere a child is the next Avatar. The sages of that child's nation will find them, and when they are sixteen they will be told. Until then, this world belongs to the rest of us. I find that frightening and also rather hopeful.",
			"People ask us who killed the Avatar as if we must know. We know the sea was rough, the Avatar was tired, and men were afraid. Usually that is enough to explain anything. Usually."].pick_random()]
		refresh()))
	o.add_child(UI.option("Leave", close))

func _explore() -> void:
	var s: Dictionary = GS.settlements[sid]
	s.explored = true
	var txt := ""
	match sid:
		"wan_shi_tong":
			txt = "A great owl watches you from the shadows while you read. You find a Fire Sage's reckoning of the Great Comet's returns, century by century, and a treatise on command annotated in four hands. The owl watches what you copy. (+1 Intelligence, +400 xp)"
			GS.player.attrs.int += 1
			GS.give_player_xp(400)
		"two_lovers":
			txt = "You give up your torch, as the old song says to, and the crystals in the ceiling light the way. At the centre of the maze, between two stone tombs, pilgrims have left offerings for a thousand years: you leave one too, and take the old coins a badgermole has dug up and left in a heap like a joke. (+600 gold)"
			GS.add_gold(600)
		_:
			txt = "You find nothing of interest."
	GS.add_renown(5)
	GS.log_msg("Explored %s." % Data.settlements[sid].name, Color(0.8, 0.9, 1))
	note = txt
	refresh()

# ---------------------------------------------------------------------------
func _build_tavern(o: VBoxContainer) -> void:
	var s: Dictionary = GS.settlements[sid]
	var t: Dictionary = s.tavern
	o.add_child(UI.rich("The tavern is warm and smells of jasmine tea and roast komodo-chicken.", 740))
	if t.has("rumor"):
		o.add_child(UI.rich("A traveller mutters: [i]\"%s\"[/i]" % t.rumor, 740))
	if t.has("merc"):
		var m: Dictionary = t.merc
		var cost := Economy.merc_cost(m.id)
		var room := GS.party_limit() - GS.party_size()
		var n := mini(m.n, room)
		o.add_child(UI.option("Hire %d %s for %d gold each" % [m.n, Data.troop(m.id).name, cost], func():
			var can := mini(n, int(GS.player.gold / cost))
			if can <= 0:
				note = UI.color_text("You can't afford them or have no room in your party.", UI.RED)
			else:
				GS.add_gold(-can * cost)
				Roster.add(GS.player_party().roster, m.id, can)
				m.n -= can
				if m.n <= 0:
					t.erase("merc")
				note = UI.color_text("Hired %d %s." % [can, Data.troop(m.id).name], UI.GREEN)
			refresh(), n > 0))
	if t.has("companion"):
		var cid: String = t.companion
		var cd: Dictionary = Data.companions[cid]
		o.add_child(UI.rich("[b]%s[/b] sits alone in a corner. \"%s\"" % [cd.name, cd.pitch], 740))
		o.add_child(UI.option("Hire %s for %d gold" % [cd.name, cd.cost], func():
			if GS.player.gold < cd.cost:
				note = UI.color_text("You can't afford it.", UI.RED)
			else:
				GS.add_gold(-cd.cost)
				GS.player.companions.append(cid)
				GS.companion_state(cid).approval = 10
				Story.set_flag("joined_" + cid, GS.day())
				t.erase("companion")
				GS.log_msg("%s has joined your party." % cd.name, Color(0.6, 1, 0.6))
				note = UI.color_text("%s joins you." % cd.name, UI.GREEN)
			refresh()))
	if t.get("ransom", false):
		var pr: Array = GS.player_party().prisoners
		var value := 0
		for st in pr:
			value += Economy.ransom_value(st.id) * st.n
		o.add_child(UI.option("Sell your prisoners to the ransom broker (%d gold)" % value, func():
			GS.add_gold(value)
			pr.clear()
			note = UI.color_text("Sold your prisoners for %d gold." % value, UI.GREEN)
			refresh(), value > 0))
	if t.get("ransom", false):
		for lid in GS.player.get("captive_lords", []).duplicate():
			o.add_child(UI.option("Ransom %s back to their family (%d gold)" % [Data.lords[lid].name, GS.lord_ransom(lid)], func():
				GS.release_lord(lid, true)
				refresh()))
	o.add_child(UI.option("Buy a round of drinks for everyone (40 gold)", func():
		if GS.player.gold >= 40:
			GS.add_gold(-40)
			s.relation = mini(100, s.relation + 2)
			GS.player.morale = minf(100.0, GS.player.morale + 3.0)
			note = "The patrons cheer your name."
		refresh(), GS.player.gold >= 40))
	o.add_child(UI.option("Play a game of Pai Sho (wager 50 gold)", _pai_sho, GS.player.gold >= 50))
	o.add_child(UI.option("Back", func(): _go("main")))

func _build_arena(o: VBoxContainer) -> void:
	var r: int = GS.flags.get("arena_round", 0)
	var f: Dictionary = Data.arena_fighters[r]
	o.add_child(UI.rich("Torches blaze around a ring of stone sunk into the earth. Madam Gu, the promoter, works the crowd from a balcony: [i]\"Gaoling! Who wants to see someone get THROWN?\"[/i]", 740))
	if GS.flags.get("arena_champion", false):
		o.add_child(UI.rich("[b]You are a former champion of the Stone Pit.[/b]", 740))
	o.add_child(UI.rich("Round %d of %d — your opponent: [b]%s[/b] (%s). Prize: %d gold." % [r + 1, Data.arena_fighters.size(), f.name, Data.element_name(f.bend), f.prize], 740))
	o.add_child(UI.rich("[i]You fight alone. Lose, and you start again from the first round.[/i]", 740))
	o.add_child(UI.option("Step into the ring (entry fee 20 gold)", func():
		GS.add_gold(-20)
		GS.start_arena(r), GS.player.gold >= 20 and GS.player.hp > GS.max_hp() * 0.3))
	if GS.player.hp <= GS.max_hp() * 0.3:
		o.add_child(UI.rich(UI.color_text("You are too badly hurt to fight. Rest first.", UI.RED), 740))
	o.add_child(UI.option("Back", func(): _go("main")))

func _pai_sho() -> void:
	var chance = 0.4 + GS.attr("int") * 0.008 + GS.attr("lck") * 0.006 + GS.skill("tactics") * 0.02
	if randf() < chance:
		GS.add_gold(50)
		note = ["You hold your lotus tile back until the last move, and it wins the game. Your opponent bows. (+50 gold)", "A clever arrangement of tiles wins the game. (+50 gold)"].pick_random()
	else:
		GS.add_gold(-50)
		note = ["A grandmother with ink-stained fingers takes your money, and then, kindly, your next move apart. (-50 gold)", "You lose badly. (-50 gold)"].pick_random()
	refresh()

func _build_recruit(o: VBoxContainer) -> void:
	var s: Dictionary = GS.settlements[sid]
	var tid := Economy.recruit_troop(sid)
	var cost := Economy.recruit_cost(sid)
	if s.relation < -10:
		o.add_child(UI.rich("The villagers refuse to follow you.", 740))
	else:
		o.add_child(UI.rich("%d young people are willing to join you as %s (%d gold each)." % [s.volunteers, Data.troop(tid).name, cost], 740))
		var room := GS.party_limit() - GS.party_size()
		var n := mini(s.volunteers, mini(room, int(GS.player.gold / cost)))
		o.add_child(UI.option("Recruit %d" % n, func():
			GS.add_gold(-n * cost)
			Roster.add(GS.player_party().roster, tid, n)
			s.volunteers -= n
			note = UI.color_text("%d %s join your party." % [n, Data.troop(tid).name], UI.GREEN)
			page = "main"
			refresh(), n > 0))
		if room <= 0:
			o.add_child(UI.rich("[i](Your party is full. Raise Leadership or Charisma, or gain renown.)[/i]", 740))
	o.add_child(UI.option("Back", func(): _go("main")))

func _build_hall(o: VBoxContainer) -> void:
	var s: Dictionary = GS.settlements[sid]
	var owner: String = s.owner
	if owner == "player":
		o.add_child(UI.rich("Your own hall. Your servants bow as you enter.", 740))
		o.add_child(UI.option("Back", func(): _go("main")))
		return
	var present := ""
	var pos: Vector2 = Data.settlements[sid].pos
	for lid in GS.lords:
		var lr: Dictionary = GS.lords[lid]
		if lr.party != "" and GS.parties.has(lr.party) and GS.parties[lr.party].pos.distance_to(pos) < 10.0 and lr.faction == s.faction:
			present = lid
			if lid == owner:
				break
	if present == "":
		o.add_child(UI.rich("The lord is away. A servant offers you tea while you wait.", 740))
		o.add_child(UI.option("Back", func(): _go("main")))
		return
	var ld: Dictionary = Data.lords[present]
	o.add_child(UI.rich("[b]%s[/b] is here." % ld.name, 740))
	o.add_child(UI.option("Speak with %s" % ld.name, func():
		var ew = load("res://scripts/ui/encounter_window.gd").new()
		ew.pid = GS.lords[present].party
		ew.page = "talk"
		_open(ew)))
	o.add_child(UI.option("Back", func(): _go("main")))
