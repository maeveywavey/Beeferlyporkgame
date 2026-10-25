extends "res://scripts/ui/window_base.gd"
## Equipment and carried goods.

const ShopWindow = preload("res://scripts/ui/shop_window.gd")

var map

func _init() -> void:
	window_size = Vector2(900, 620)

func build() -> void:
	set_title("Inventory")
	var pl: Dictionary = GS.player
	var cols := UI.hbox(24)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)
	var left := UI.vbox(6)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	left.add_child(UI.label("Equipped", 19, UI.BROWN))
	var names := {"weapon": "Melee", "ranged": "Ranged", "armor": "Body", "helmet": "Head", "mount": "Mount"}
	for slot in ["weapon", "ranged", "armor", "helmet", "mount"]:
		var id: String = pl.equip.get(slot, "")
		var row := UI.hbox()
		var txt := "%s: %s" % [names[slot], Data.item(id).name if id != "" else "—"]
		if id != "" and id != "fists":
			txt += "\n   " + ShopWindow.item_stats(id)
		var l := UI.label(txt, 15)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		if id != "" and id != "fists":
			row.add_child(UI.button("Remove", _unequip.bind(slot), 90))
		left.add_child(row)
	left.add_child(UI.spacer(8))
	left.add_child(UI.label("Bag", 19, UI.BROWN))
	var sc := UI.scroll(220)
	left.add_child(sc)
	var list := UI.vbox(3)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	if pl.items.is_empty():
		list.add_child(UI.label("(empty)", 15, UI.BROWN))
	for i in pl.items.size():
		var id2: String = pl.items[i]
		var row2 := UI.hbox()
		var l2 := UI.label("%s — %s" % [Data.item(id2).name, ShopWindow.item_stats(id2)], 15)
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(l2)
		row2.add_child(UI.button("Equip", func():
			ShopWindow.equip_item(i)
			refresh(), 70))
		list.add_child(row2)
	var right := UI.vbox(4)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	right.add_child(UI.label("Goods (food: %.1f days)" % GS.food_days(), 19, UI.BROWN))
	if pl.goods.is_empty():
		right.add_child(UI.label("(none)", 15, UI.BROWN))
	for g in pl.goods:
		right.add_child(UI.label("%s x%d%s" % [Data.goods[g].name, pl.goods[g], "  (food)" if Data.goods[g].food else ""], 15))
	right.add_child(UI.spacer(10))
	right.add_child(UI.rich("Armour: %d    Max HP: %d" % [GS.player_armor(), GS.max_hp()], 360))
	var b := UI.hbox()
	content.add_child(b)
	b.add_child(UI.expand())
	b.add_child(UI.button("Done", close, 120))

func _unequip(slot: String) -> void:
	var id: String = GS.player.equip[slot]
	GS.player.items.append(id)
	GS.player.equip[slot] = "fists" if slot == "weapon" else ""
	refresh()
