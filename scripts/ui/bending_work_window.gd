extends "res://scripts/ui/window_base.gd"
## Non-combat bending (the element expansions): what you and your bending
## companions can do here, or around camp. Unavailable jobs say why.

const Work = preload("res://scripts/core/bending_work.gd")

var map
var sid := ""          # "" means camp
var note := ""
var picking_temple := false

func _init() -> void:
	window_size = Vector2(900, 620)

func build() -> void:
	set_title("Bending at Work" + ("" if sid == "" else " — " + Data.settlements[sid].name))
	content.add_child(UI.rich("[i]Bending is mostly used for ordinary things: kilns, wells, fields, sails. Any companion who bends an element can do its work.[/i]", 860))
	if note != "":
		content.add_child(UI.rich(note, 860))
	content.add_child(UI.sep())
	var sc := UI.scroll(420)
	content.add_child(sc)
	var list := UI.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	if picking_temple:
		list.add_child(UI.label("Where should the bison fly?", 18, UI.BROWN))
		for t in Data.settlements:
			if Data.settlements[t].type == "temple" and t != sid:
				list.add_child(UI.option(Data.settlements[t].name, func():
					note = Work.perform("bison", sid, t)
					picking_temple = false
					close()))
		list.add_child(UI.option("Never mind", func():
			picking_temple = false
			refresh()))
	else:
		var shown := 0
		for el in ["fire", "water", "earth", "air"]:
			var ids: Array = Work.available(sid).filter(func(i): return Work.WORK[i].element == el)
			if ids.is_empty():
				continue
			list.add_child(UI.label(Data.element_name(el), 18, UI.BROWN))
			for id in ids:
				var w: Dictionary = Work.WORK[id]
				var why := Work.blocker(id, sid)
				var who := Work.doer(el)
				var head := "%s%s" % [w.name, ("  (%s, %dh%s)" % [Work.doer_name(who), int(w.hours), ", %d gold" % int(w.gold) if w.has("gold") else ""]) if who != "" else ""]
				var b := UI.option(head, _do.bind(id), why == "")
				b.tooltip_text = w.desc
				list.add_child(b)
				list.add_child(UI.rich("[font_size=14][i]%s%s[/i][/font_size]" % [w.desc, ("  — " + UI.color_text(why, UI.RED)) if why != "" else ""], 840))
				shown += 1
		if shown == 0:
			list.add_child(UI.rich("Nothing here calls for bending. (The element expansions may be switched off in Settings.)", 840))
	var b2 := UI.hbox()
	content.add_child(b2)
	b2.add_child(UI.expand())
	b2.add_child(UI.button("Done", close, 120))

func _do(id: String) -> void:
	if id == "bison":
		picking_temple = true
		refresh()
		return
	note = Work.perform(id, sid)
	refresh()
