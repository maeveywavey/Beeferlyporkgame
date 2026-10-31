extends "res://scripts/ui/window_base.gd"
## Party screen: troops, upgrades, companions and prisoners.

const Roster = preload("res://scripts/core/roster.gd")

var map
var selected := ""
static var _prisoners_open := true

func _init() -> void:
	window_size = Vector2(1100, 680)

static func troop_summary(id: String) -> String:
	var t: Dictionary = Data.troop(id)
	var w: Dictionary = Data.item(t.weapon)
	var s := "Tier %d %s\nHP %d   Armour %d   Skill %d\nWeapon: %s" % [t.tier, Data.factions.get(_culture_faction(t.culture), Data.factions.neutral).short, t.hp, t.armor, t.skill, w.name]
	if t.shield:
		s += " + shield"
	if t.ranged != "":
		s += "\nRanged: %s" % Data.item(t.ranged).name
	if t.bend != "":
		s += "\nBending: %s (power %.1f)" % [Data.element_name(t.bend), t.bend_power]
	if t.mount != "":
		s += "\nMount: %s" % Data.item(t.mount).name
	if t.healer:
		s += "\nHealer: mends allies in battle and speeds recovery."
	s += "\nWage: %d / week" % Data.troop_wage(id)
	return s

static func _culture_faction(c: String) -> String:
	match c:
		"fire": return "fire_nation"
		"north": return "northern_water"
		"south": return "southern_water"
		"air": return "neutral"
		"sun": return "sun_warriors"
		"hamakaze": return "tide_wardens"
	return "earth_kingdom"

func build() -> void:
	var pp: Dictionary = GS.player_party()
	set_title("Party — %d / %d" % [GS.party_size(), GS.party_limit()])
	var wages = int(Roster.wages(pp.roster) * (1.0 - GS.skill("leadership") * 0.05)) + GS.player.companions.size() * 15
	content.add_child(UI.rich("Weekly wages: [b]%d[/b] gold    Morale: %d    Gold: %d" % [wages, int(GS.player.morale), GS.player.gold], 1000))
	var cols := UI.hbox(18)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)
	# Troops
	var left := UI.vbox(4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.6
	cols.add_child(left)
	left.add_child(UI.label("Troops", 19, UI.BROWN))
	var sc := UI.scroll(480)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sc)
	var list := UI.vbox(4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	list.add_child(UI.label("Heroes", 15, UI.BROWN))
	list.add_child(UI.label("%s (you) — HP %d/%d" % [GS.player.name, GS.player.hp, GS.max_hp()], 16, UI.BLUE))
	for cid in GS.player.companions:
		var row := UI.hbox()
		var wounded: bool = GS.companion_state(cid).wounded
		var l := UI.label("%s (companion)%s" % [Data.companions[cid].name, " — wounded" if wounded else ""], 16, UI.BLUE)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		if not Data.companions[cid].get("story_only", false):
			var dis := UI.button("Send away", _dismiss_companion.bind(cid))
			dis.tooltip_text = "%s leaves your party." % Data.companions[cid].name
			row.add_child(dis)
		list.add_child(row)
	Roster.sort_by_tier(pp.roster)
	list.add_child(UI.label("Troops (%d, highest tier first)" % Roster.total(pp.roster), 15, UI.BROWN))
	for s in pp.roster:
		list.add_child(_troop_row(s))
	# Right column: details + prisoners
	var right := UI.vbox(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	right.add_child(UI.label("Details", 19, UI.BROWN))
	var det := UI.label(troop_summary(selected) if selected != "" else "Click a troop name to see details.", 15, UI.INK, true)
	det.custom_minimum_size = Vector2(320, 180)
	right.add_child(det)
	right.add_child(UI.sep())
	var ph := UI.button("%s Prisoners (%d / %d)" % ["▼" if _prisoners_open else "▶", Roster.total(pp.prisoners), GS.prisoner_limit()], func():
		_prisoners_open = not _prisoners_open
		refresh(), 0)
	ph.flat = true
	ph.alignment = HORIZONTAL_ALIGNMENT_LEFT
	ph.tooltip_text = "Show or hide the prisoner list."
	right.add_child(ph)
	if not _prisoners_open:
		var b0 := UI.hbox()
		content.add_child(b0)
		b0.add_child(UI.expand())
		b0.add_child(UI.button("Done", close, 120))
		return
	var sc2 := UI.scroll(200)
	right.add_child(sc2)
	var plist := UI.vbox(3)
	plist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc2.add_child(plist)
	for s in pp.prisoners:
		var row2 := UI.hbox()
		var l2 := UI.label("%s x%d" % [Data.troop(s.id).name, s.n], 15)
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(l2)
		row2.add_child(UI.button("Recruit", _recruit_prisoner.bind(s.id), 80, GS.party_size() < GS.party_limit()))
		plist.add_child(row2)
	for lid in GS.player.get("captive_lords", []):
		var lrow := UI.hbox()
		var ll := UI.label("%s (noble captive)" % Data.lords[lid].name, 15, UI.RED)
		ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lrow.add_child(ll)
		lrow.add_child(UI.button("Release", func():
			GS.release_lord(lid, false)
			refresh(), 80))
		if not GS.is_king(lid):
			var ex := UI.button("Execute", func():
				GS.execute_lord(lid)
				refresh(), 80)
			ex.tooltip_text = "Cruelty is remembered: +60 infamy, and their nation will never forgive it."
			lrow.add_child(ex)
		plist.add_child(lrow)
	if not pp.prisoners.is_empty():
		right.add_child(UI.button("Release all prisoners (+honour)", func():
			GS.player.honor = GS.player.get("honor", 0) + 1
			pp.prisoners.clear()
			refresh()))
	var b := UI.hbox()
	content.add_child(b)
	b.add_child(UI.expand())
	b.add_child(UI.button("Done", close, 120))

func _troop_row(s: Dictionary) -> Control:
	var t: Dictionary = Data.troop(s.id)
	var v := UI.vbox(2)
	var row := UI.hbox(6)
	v.add_child(row)
	var name_btn := Button.new()
	name_btn.text = "T%d  %s  x%d%s" % [t.tier, t.name, s.n, (" (%d wounded)" % s.w) if s.w > 0 else ""]
	name_btn.flat = true
	name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_btn.add_theme_color_override("font_color", UI.INK)
	name_btn.add_theme_color_override("font_hover_color", UI.RED)
	name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_btn.focus_mode = Control.FOCUS_NONE
	name_btn.pressed.connect(func():
		selected = s.id
		refresh())
	row.add_child(name_btn)
	var need := Data.troop_xp_needed(s.id)
	if not Data.troop_upgrades(s.id).is_empty():
		var bar := UI.bar(float(s.xp) / maxf(1.0, need * s.n) * 100.0, 100.0, UI.GOLD, 90, 10)
		bar.tooltip_text = "Experience: %d (needs %d per troop)" % [s.xp, need]
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		row.add_child(UI.label("XP %d / %d" % [s.xp, need * s.n], 13, UI.INK))
	var dis1 := UI.button("Dismiss 1", func():
		Roster.remove(GS.player_party().roster, s.id, 1)
		refresh(), 0)
	dis1.tooltip_text = "Release one %s from your service (no refund)." % t.name
	row.add_child(dis1)
	var can := Roster.upgradable_count(s)
	if can > 0:
		var head := UI.label("   Ready to upgrade (%d):" % can, 14, UI.GREEN)
		v.add_child(head)
		# one row per path: the target and cost, then [Upgrade 1] and [All n]
		for u in Data.troop_upgrades(s.id):
			var cost := Data.troop_upgrade_cost(u)
			var urow := UI.hbox(6)
			urow.add_child(UI.label("        → %s (T%d, %d g)" % [Data.troop(u).name, Data.troop(u).tier, cost], 14, UI.INK))
			urow.add_child(UI.expand())
			var ub := UI.button("Upgrade 1", _upgrade.bind(s.id, u, 1), 0, GS.player.gold >= cost)
			ub.tooltip_text = "Upgrade one for %d gold." % cost
			urow.add_child(ub)
			if can > 1:
				var ab := UI.button("All %d · %d g" % [can, cost * can], _upgrade.bind(s.id, u, can), 0, GS.player.gold >= cost * can)
				ab.tooltip_text = "Upgrade all %d that are ready." % can
				urow.add_child(ab)
			v.add_child(urow)
	return v

func _upgrade(id: String, target: String, n: int) -> void:
	var cost := Data.troop_upgrade_cost(target)
	n = mini(n, int(GS.player.gold / cost))
	var done := Roster.upgrade(GS.player_party().roster, id, target, n)
	GS.add_gold(-done * cost)
	selected = target
	refresh()

func _recruit_prisoner(id: String) -> void:
	var pp: Dictionary = GS.player_party()
	Roster.remove(pp.prisoners, id, 1, true)
	Roster.add(pp.roster, id, 1)
	GS.player.morale = maxf(0.0, GS.player.morale - 1.0)
	refresh()

func _dismiss_companion(cid: String) -> void:
	GS.player.companions.erase(cid)
	GS.log_msg("%s has left your party." % Data.companions[cid].name)
	refresh()
