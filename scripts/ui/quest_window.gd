extends "res://scripts/ui/window_base.gd"
## Quest log.

var map

func _init() -> void:
	window_size = Vector2(820, 560)

func build() -> void:
	set_title("Quest Log")
	var sc := UI.scroll(440)
	content.add_child(sc)
	var list := UI.vbox(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	var any := false
	for q in GS.quests:
		if q.status != "active":
			continue
		any = true
		var left := maxf(0.0, (q.deadline - GS.hours) / 24.0)
		list.add_child(UI.rich("[b]%s[/b]  (%.1f days left)\n%s" % [q.title, left, q.desc], 760))
		list.add_child(UI.sep())
	if not any:
		list.add_child(UI.rich("You have no active quests. Village elders, guild masters and castle stewards may have work for you.", 760))
	var done := GS.quests.filter(func(q): return q.status != "active")
	if not done.is_empty():
		list.add_child(UI.label("Finished", 19, UI.BROWN))
		for q in done.slice(-10):
			list.add_child(UI.label("%s — %s" % [q.title, "completed" if q.status == "done" else "failed"], 15, UI.GREEN if q.status == "done" else UI.RED))
	var b := UI.hbox()
	content.add_child(b)
	b.add_child(UI.expand())
	b.add_child(UI.button("Done", close, 120))
