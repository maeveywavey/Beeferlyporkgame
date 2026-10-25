extends "res://scripts/ui/window_base.gd"
## Mount & Blade style text menu for a settlement.

const Roster = preload("res://scripts/core/roster.gd")
const Economy = preload("res://scripts/core/economy.gd")
const Quests = preload("res://scripts/core/quests.gd")
const AutoResolve = preload("res://scripts/core/auto_resolve.gd")

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
	var header := "[b]%s[/b] of the %s" % [d.type.capitalize(), Data.factions.get(s.faction, Data.factions.neutral).name]
	if s.owner == "player":
		header += " — [color=#2a6a2a]your fief[/color]"
	elif Data.lords.has(s.owner):
		header += " — held by %s" % Data.lords[s.owner].name
	if d.type != "ruin":
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
	if d.type == "ruin":
		_build_ruin(o)
		return
	if s.siege.get("leader", "") == "player":
		_build_player_siege(o)
		return
	if hostile:
		if d.type == "village":
			if s.looted_until < GS.hours:
				o.add_child(UI.option("Raid the village (dishonourable)", _raid))
			o.add_child(UI.option("Leave", close))
		else:
			o.add_child(UI.rich("The gates are shut against you. Archers watch you from the walls.", 740))
			o.add_child(UI.option("Lay siege to %s" % d.name, _begin_siege, GS.party_size() >= 10))
			if GS.party_size() < 10:
				o.add_child(UI.rich("[i](You need at least 10 men to besiege.)[/i]", 740))
			o.add_child(UI.option("Leave", close))
		return
	# Friendly or neutral settlement
	if not s.siege.is_empty() and GS.at_war(s.siege.faction, s.faction) and GS.at_war(s.siege.faction, pf):
		o.add_child(UI.option("Break the siege! Attack the besiegers", _defend))
	for q in Quests.deliverable_at(sid):
		o.add_child(UI.option("Deliver: %s" % q.title, func():
			if Quests.try_deliver(sid):
				note = UI.color_text("Delivered!", UI.GREEN)
			else:
				note = UI.color_text("You don't have what was asked for yet.", UI.RED)
			refresh()))
	match d.type:
		"town":
			o.add_child(UI.option("Visit the marketplace", func(): _open(_mk("res://scripts/ui/trade_window.gd"))))
			o.add_child(UI.option("Visit the weaponsmith and armourer", func(): _open(_mk("res://scripts/ui/shop_window.gd")), s.looted_until < GS.hours))
			o.add_child(UI.option("Go to the tavern", func(): _go("tavern")))
			o.add_child(UI.option("Go to the lord's hall", func(): _go("hall")))
			o.add_child(UI.option("Speak with the guild master (work)", _ask_work))
		"castle":
			o.add_child(UI.option("Go to the lord's hall", func(): _go("hall")))
			o.add_child(UI.option("Speak with the castle steward (work)", _ask_work))
		"village":
			if s.looted_until < GS.hours:
				o.add_child(UI.option("Recruit volunteers (%d available)" % s.volunteers, func(): _go("recruit")))
				o.add_child(UI.option("Buy supplies from the villagers", func(): _open(_mk("res://scripts/ui/trade_window.gd"))))
			o.add_child(UI.option("Speak with the village elder (work)", _ask_work))
	if s.owner == "player" and d.type != "village":
		o.add_child(UI.option("Manage the garrison", func(): _open(_mk("res://scripts/ui/garrison_window.gd"))))
	o.add_child(UI.option("Rest here for a day (heal faster)", _rest.bind(24.0)))
	o.add_child(UI.option("Wait here until healed", _rest.bind(-2.0), Roster.wounded(GS.player_party().roster) > 0 or GS.player.hp < GS.max_hp()))
	o.add_child(UI.option("Leave", close))

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
	if Data.lords.has(s.owner):
		GS.change_lord_rel(s.owner, -15)
	GS.log_msg("You raided %s, taking %d gold and supplies." % [d.name, gold], Color(1, 0.6, 0.3))
	note = "Your men loot the village. Smoke rises behind you."
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
	if sid == "jets_hideout":
		o.add_child(UI.rich("Wooden platforms creak high above you. Someone is watching from the trees.", 740))
		if not GS.at_war("freedom_fighters", GS.player_faction()) and not GS.player.companions.has("jet"):
			o.add_child(UI.option("Call out to the Freedom Fighters", func():
				note = "[b]Jet:[/b] \"Anyone who fights the Fire Nation is a friend of ours. Kill some firebenders for me.\""
				if GS.player.get("faction", "") == "fire_nation":
					note = "[b]Jet:[/b] \"You serve the Fire Nation? Get out of my forest.\""
				refresh()))
		o.add_child(UI.option("Leave", close))
		return
	if not s.explored:
		o.add_child(UI.option("Explore the ruins", _explore))
	else:
		o.add_child(UI.rich("You have already explored this place.", 740))
	o.add_child(UI.option("Leave", close))

func _explore() -> void:
	var s: Dictionary = GS.settlements[sid]
	s.explored = true
	var txt := ""
	match sid:
		"southern_air_temple":
			txt = "Among the bones of fallen Fire Nation soldiers you find the sanctuary of the Avatars. Gazing at the statues of Roku, Kyoshi and Kuruk, you feel wiser. (+1 Intelligence, +500 xp)"
			GS.player.attrs.int += 1
			GS.give_player_xp(500)
		"northern_air_temple":
			txt = "The Mechanist's refugees greet you warmly. In return for news from outside, the Mechanist gives you a pouch of coin and a clever folding bow. (+300 gold, Short Bow)"
			GS.add_gold(300)
			GS.player.items.append("short_bow")
		"eastern_air_temple":
			txt = "An old guru teaches you to open your chakras. You feel the energy flow freely through you. (+2 skill points)"
			GS.player.skill_points += 2
		"western_air_temple":
			txt = "Hanging beneath the cliff, the temple holds old Air Nomad training grounds. Leaping between the platforms hones your agility. (+1 Agility, +300 xp)"
			GS.player.attrs.agi += 1
			GS.give_player_xp(300)
		"wan_shi_tong":
			txt = "Inside the sunken library you find a star chart showing the day the sun will go dark. Knowledge is power. (+1 Tactics, +400 xp)"
			GS.player.skills.tactics += 1
			GS.give_player_xp(400)
		"taku":
			txt = "Digging through the rubble of Taku you uncover a hidden strongbox. (+600 gold)"
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
	o.add_child(UI.option("Buy a round of drinks for everyone (40 gold)", func():
		if GS.player.gold >= 40:
			GS.add_gold(-40)
			s.relation = mini(100, s.relation + 2)
			GS.player.morale = minf(100.0, GS.player.morale + 3.0)
			note = "The patrons cheer your name."
		refresh(), GS.player.gold >= 40))
	o.add_child(UI.option("Play a game of Pai Sho (wager 50 gold)", _pai_sho, GS.player.gold >= 50))
	o.add_child(UI.option("Back", func(): _go("main")))

func _pai_sho() -> void:
	var chance = 0.4 + GS.player.attrs.int * 0.012 + GS.skill("tactics") * 0.02
	if randf() < chance:
		GS.add_gold(50)
		note = ["You play the White Lotus gambit. Your opponent bows in defeat. (+50 gold)", "A clever arrangement of tiles wins the game. (+50 gold)"].pick_random()
	else:
		GS.add_gold(-50)
		note = ["An old man in green robes smiles and takes your money. \"The White Lotus... never mind.\" (-50 gold)", "You lose badly. (-50 gold)"].pick_random()
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
