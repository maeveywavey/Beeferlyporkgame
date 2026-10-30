extends "res://scripts/ui/window_base.gd"
## Weaponsmith / armourer: buy and sell equipment.

const Economy = preload("res://scripts/core/economy.gd")

var sid := ""
var map

func _init() -> void:
	window_size = Vector2(900, 620)

static func item_stats(id: String) -> String:
	var it: Dictionary = Data.item(id)
	match it.slot:
		"weapon": return "dmg %d, reach %.1f, speed %.2f" % [it.dmg, it.reach, it.speed]
		"ranged": return "dmg %d, ammo %d, acc %d%%" % [it.dmg, it.ammo, int(it.accuracy * 100)]
		"armor", "helmet": return "armour %d" % it.armor
		"mount": return "speed %.0f, hp %d, armour %d" % [it.speed, it.hp, it.armor]
	return ""

func build() -> void:
	set_title("Smithy of " + Data.settlements[sid].name)
	content.add_child(UI.rich("Gold: [b]%d[/b]" % GS.player.gold, 800))
	var cols := UI.hbox(16)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(cols)
	# For sale
	var left := UI.vbox(4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	left.add_child(UI.label("For sale", 19, UI.BROWN))
	var sc := UI.scroll(420)
	left.add_child(sc)
	var list := UI.vbox(4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	for id in Economy.shop_items(sid):
		var it: Dictionary = Data.item(id)
		var price := Economy.item_buy_price(id)
		var row := UI.hbox()
		var l := UI.label("%s (%s)\n%s" % [it.name, it.slot, item_stats(id)], 15)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		row.add_child(UI.button("Buy %d" % price, _buy.bind(id, price), 110, GS.player.gold >= price))
		list.add_child(row)
	# Your items
	var right := UI.vbox(4)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	right.add_child(UI.label("Your equipment", 19, UI.BROWN))
	var sc2 := UI.scroll(420)
	right.add_child(sc2)
	var list2 := UI.vbox(4)
	list2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc2.add_child(list2)
	for slot in ["weapon", "ranged", "armor", "helmet", "mount"]:
		var eid: String = GS.player.equip.get(slot, "")
		if eid == "" or eid == "fists":
			continue
		var row2 := UI.hbox()
		var l2 := UI.label("[equipped] %s\n%s" % [Data.item(eid).name, item_stats(eid)], 15, UI.GREEN)
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(l2)
		row2.add_child(UI.button("Sell %d" % Economy.item_sell_price(eid), _sell_equipped.bind(slot), 110))
		list2.add_child(row2)
	for i in GS.player.items.size():
		var id2: String = GS.player.items[i]
		var row3 := UI.hbox()
		var l3 := UI.label("%s\n%s" % [Data.item(id2).name, item_stats(id2)], 15)
		l3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row3.add_child(l3)
		row3.add_child(UI.button("Equip", _equip.bind(i), 70))
		row3.add_child(UI.button("Sell %d" % Economy.item_sell_price(id2), _sell_item.bind(i), 110))
		list2.add_child(row3)
	var bottom := UI.hbox()
	content.add_child(bottom)
	bottom.add_child(UI.expand())
	bottom.add_child(UI.button("Done", close, 120))

func _buy(id: String, price: int) -> void:
	if GS.player.gold < price:
		return
	GS.add_gold(-price)
	var slot: String = Data.item(id).slot
	var cur: String = GS.player.equip.get(slot, "")
	if cur == "" or cur == "fists":
		GS.player.equip[slot] = id
	else:
		GS.player.items.append(id)
	refresh()

func _sell_equipped(slot: String) -> void:
	var id: String = GS.player.equip[slot]
	GS.add_gold(Economy.item_sell_price(id))
	GS.player.equip[slot] = "fists" if slot == "weapon" else ""
	refresh()

func _sell_item(i: int) -> void:
	var id: String = GS.player.items[i]
	GS.add_gold(Economy.item_sell_price(id))
	GS.player.items.remove_at(i)
	refresh()

func _equip(i: int) -> void:
	equip_item(i)
	refresh()

static func equip_item(i: int) -> void:
	var id: String = GS.player.items[i]
	var slot: String = Data.item(id).slot
	var cur: String = GS.player.equip.get(slot, "")
	GS.player.items.remove_at(i)
	if cur != "" and cur != "fists":
		GS.player.items.append(cur)
	GS.player.equip[slot] = id
