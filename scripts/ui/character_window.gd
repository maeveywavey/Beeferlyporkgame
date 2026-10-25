extends "res://scripts/ui/window_base.gd"
## Character sheet: attributes, skills and stats.

var map

func _init() -> void:
	window_size = Vector2(1000, 660)

func build() -> void:
	var pl: Dictionary = GS.player
	set_title(pl.name)
	var bg: Dictionary = GS.BACKGROUNDS.get(pl.background, {})
	var status := "Independent"
	if pl.faction != "":
		status = "%s of the %s" % [pl.status.capitalize(), Data.factions[pl.faction].name]
	var info := "[b]%s[/b] — Level %d  (XP %d / %d)\nBending: %s    Status: %s\nHP %d    Chi %d    Renown %d    Honour %d" % [
		bg.get("name", ""), pl.level, pl.xp, GS.xp_for_level(pl.level), Data.element_name(pl.bend), status,
		GS.max_hp(), int(GS.max_chi()), pl.renown, pl.get("honor", 0)]
	content.add_child(UI.rich(info, 940))
	var cols := UI.hbox(30)
	content.add_child(cols)
	# Attributes
	var left := UI.vbox(6)
	cols.add_child(left)
	left.add_child(UI.label("Attributes (%d points)" % pl.attr_points, 19, UI.BROWN))
	var ad := {"str": "Strength — hit points, damage", "agi": "Agility — speed, weapon skills", "int": "Intelligence — bending, tactics, skill points", "cha": "Charisma — party size, leadership"}
	for a in ["str", "agi", "int", "cha"]:
		var row := UI.hbox()
		var l := UI.label("%s: %d" % [a.to_upper(), pl.attrs[a]], 17)
		l.custom_minimum_size.x = 90
		row.add_child(l)
		row.add_child(UI.button("+", _add_attr.bind(a), 34, pl.attr_points > 0))
		row.add_child(UI.label(ad[a], 14, UI.BROWN))
		left.add_child(row)
	left.add_child(UI.spacer(10))
	left.add_child(UI.label("Faction standing", 19, UI.BROWN))
	for f in Data.KINGDOMS:
		var rel: int = pl.faction_rel.get(f, 0)
		var war := GS.at_war(GS.player_faction(), f)
		left.add_child(UI.label("%s: %d%s" % [Data.factions[f].name, rel, "  (at war)" if war else ""], 15, UI.RED if war else UI.INK))
	# Skills
	var right := UI.vbox(3)
	cols.add_child(right)
	right.add_child(UI.label("Skills (%d points) — max = governing attribute / 2" % pl.skill_points, 19, UI.BROWN))
	for s in GS.SKILLS:
		var row2 := UI.hbox()
		var cap := GS.skill_cap(s)
		var val: int = pl.skills[s]
		var bonus := GS.skill(s) - val
		var l2 := UI.label("%s: %d%s" % [s.replace("_", " ").capitalize(), val, (" (+%d)" % bonus) if bonus > 0 else ""], 16)
		l2.custom_minimum_size.x = 190
		l2.tooltip_text = GS.SKILL_DESC[s]
		l2.mouse_filter = Control.MOUSE_FILTER_PASS
		row2.add_child(l2)
		var can: bool = pl.skill_points > 0 and val < cap and not (s == "bending" and pl.bend == "")
		row2.add_child(UI.button("+", _add_skill.bind(s), 34, can))
		row2.add_child(UI.label("[%s, cap %d] %s" % [GS.SKILL_ATTR[s].to_upper(), cap, GS.SKILL_DESC[s]], 13, UI.BROWN))
		right.add_child(row2)
	var b := UI.hbox()
	content.add_child(b)
	b.add_child(UI.expand())
	b.add_child(UI.button("Done", close, 120))

func _add_attr(a: String) -> void:
	if GS.player.attr_points <= 0:
		return
	GS.player.attr_points -= 1
	GS.player.attrs[a] += 1
	if a == "str":
		GS.player.hp += 2
	refresh()

func _add_skill(s: String) -> void:
	if GS.player.skill_points <= 0 or GS.player.skills[s] >= GS.skill_cap(s):
		return
	GS.player.skill_points -= 1
	GS.player.skills[s] += 1
	if s == "ironflesh":
		GS.player.hp += 4
	refresh()
