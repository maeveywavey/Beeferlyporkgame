extends "res://scripts/ui/window_base.gd"
## Buying and selling trade goods and food.

const Economy = preload("res://scripts/core/economy.gd")

var sid := ""
var map

func _init() -> void:
	window_size = Vector2(860, 620)

func build() -> void:
	set_title("Market of " + Data.settlements[sid].name)
	content.add_child(UI.rich("Gold: [b]%d[/b]    Food: %.1f days    Goods carried: %d" % [GS.player.gold, GS.food_days(), GS.goods_count()], 800))
	var sc := UI.scroll(440)
	content.add_child(sc)
	var g := UI.grid(7, 14, 6)
	sc.add_child(g)
	for h in ["Good", "Owned", "Buy", "Sell", "", "", ""]:
		g.add_child(UI.label(h, 16, UI.BROWN))
	var goods := Economy.market_goods(sid)
	# Player may sell anything they carry, even if the market doesn't list it.
	for gid in GS.player.goods:
		if not goods.has(gid):
			goods.append(gid)
	for gid in goods:
		var gd: Dictionary = Data.goods[gid]
		var owned: int = GS.player.goods.get(gid, 0)
		var bp := Economy.buy_price(sid, gid)
		var sp := Economy.sell_price(sid, gid)
		var produced: bool = Economy.local_production(sid).has(gid)
		var name: String = gd.name + (" (food)" if gd.food else "") + (" *" if produced else "")
		g.add_child(UI.label(name, 16))
		g.add_child(UI.label(str(owned), 16))
		g.add_child(UI.label(str(bp), 16, UI.RED if bp > gd.price * 1.2 else (UI.GREEN if bp < gd.price * 0.8 else UI.INK)))
		g.add_child(UI.label(str(sp), 16, UI.GREEN if sp > gd.price * 1.1 else UI.INK))
		g.add_child(UI.button("Buy", _buy.bind(gid, 1), 60, GS.player.gold >= bp))
		g.add_child(UI.button("Buy 5", _buy.bind(gid, 5), 70, GS.player.gold >= bp * 5))
		g.add_child(UI.button("Sell", _sell.bind(gid, 1), 60, owned > 0))
		# grid needs 7 columns: add the Sell all button on the next row only when owned
	content.add_child(UI.rich("[i]* produced locally (cheaper here). Food keeps your party fed: 1 unit feeds 5 men for a day. Variety raises morale.[/i]", 800))
	var row := UI.hbox()
	content.add_child(row)
	row.add_child(UI.button("Sell all non-food goods", _sell_all))
	row.add_child(UI.expand())
	row.add_child(UI.button("Done", close, 120))

func _buy(gid: String, n: int) -> void:
	for i in n:
		if not Economy.buy(sid, gid):
			break
	refresh()

func _sell(gid: String, n: int) -> void:
	for i in n:
		if not Economy.sell(sid, gid):
			break
	refresh()

func _sell_all() -> void:
	for gid in GS.player.goods.keys():
		if not Data.goods[gid].food:
			while int(GS.player.goods.get(gid, 0)) > 0:
				if not Economy.sell(sid, gid):
					break
	refresh()
