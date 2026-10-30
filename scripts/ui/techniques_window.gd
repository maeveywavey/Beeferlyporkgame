extends "res://scripts/ui/window_base.gd"
## The element expansions' techniques: your art's styles, what you know, where
## the rest are taught, and which ability sits on Q, E and R in battle.

const Tech = preload("res://scripts/battle/techniques.gd")
const Bending = preload("res://scripts/battle/bending.gd")
const Forms = preload("res://scripts/battle/forms.gd")
const DLC = preload("res://scripts/dlc/registry.gd")

var map
var art := ""

func _init() -> void:
	window_size = Vector2(1120, 700)

func _ready() -> void:
	art = Forms.art_of(GS.player.get("bend", ""))
	if not GS.player.has("loadout"):
		GS.player.loadout = {}
	super._ready()

func build() -> void:
	set_title("Techniques")
	if art == "":
		content.add_child(UI.rich("You are not a bender. Your companions' techniques show in battle; their non-combat bending is under \"Bending at work\" in settlements and camp.", 1060))
		content.add_child(UI.button("Close", close, 120))
		return
	if not DLC.enabled(art):
		content.add_child(UI.rich("The %s expansion is switched off in Settings." % DLC.EXPANSIONS[art].name, 1060))
		content.add_child(UI.button("Close", close, 120))
		return
	var title: String = GS.player.get("master_title", "")
	content.add_child(UI.rich("[b]%s[/b] — %s%s" % [DLC.EXPANSIONS[art].name, DLC.EXPANSIONS[art].tagline, ("   [color=#2a6a2a]%s[/color]" % title) if title != "" else ""], 1060))
	var cols := UI.hbox(18)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)
	# Left: catalogue by style
	var sc := UI.scroll(520)
	sc.custom_minimum_size.x = 700
	cols.add_child(sc)
	var list := UI.vbox(4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	for style in Tech.STYLES[art]:
		var st: Dictionary = Tech.STYLES[art][style]
		list.add_child(UI.label("%s  ·  %s" % [st.name, st.basis], 18, UI.BROWN))
		list.add_child(UI.rich("[font_size=14][i]%s[/i][/font_size]" % st.desc, 680))
		for id in Tech.for_element(art):
			var t: Dictionary = Tech.TECHNIQUES[id]
			if t.style != style:
				continue
			var known := Tech.known(id)
			var a: Dictionary = t.ability
			var stats := "chi %d · %.1fs" % [int(a.cost), float(a.cd)]
			if a.has("dmg"):
				stats += " · dmg %d" % int(a.dmg)
			var txt := "[b]%s[/b]  (%s)  %s\n%s" % [t.name, stats, UI.color_text("known", UI.GREEN) if known else UI.color_text("taught by: " + t.from, UI.RED), t.desc]
			list.add_child(UI.rich(txt, 680))
	# Right: loadout
	var right := UI.vbox(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	right.add_child(UI.label("In battle", 18, UI.BROWN))
	var lo: Dictionary = GS.player.loadout
	for slot in ["q", "e", "r"]:
		var base: Dictionary = Bending.ability(GS.player.bend, slot)
		var cur: String = lo.get(slot, "")
		right.add_child(UI.label("%s: %s" % [slot.to_upper(), Tech.TECHNIQUES[cur].name if cur != "" and Tech.TECHNIQUES.has(cur) else base.get("name", "-")], 17))
		var row := UI.grid(2, 4, 4)
		right.add_child(row)
		var bb := UI.button(base.get("name", "basic"), func():
			lo.erase(slot)
			refresh(), 140)
		if cur == "":
			UI.mark_selected(bb)
		row.add_child(bb)
		for id in GS.player.get("techniques", []):
			if not Tech.TECHNIQUES.has(id) or Tech.TECHNIQUES[id].element != art:
				continue
			var tb := UI.button(Tech.TECHNIQUES[id].name, func():
				lo[slot] = id
				refresh(), 140)
			if cur == id:
				UI.mark_selected(tb)
			row.add_child(tb)
	right.add_child(UI.rich("[i]Learned techniques also open new movements in the Bending Forms designer. Known: %d of %d.[/i]" % [GS.player.get("techniques", []).filter(func(x): return Tech.TECHNIQUES.has(x) and Tech.TECHNIQUES[x].element == art).size(), Tech.for_element(art).size()], 340))
	var b := UI.hbox()
	content.add_child(b)
	b.add_child(UI.expand())
	b.add_child(UI.button("Done", close, 120))
