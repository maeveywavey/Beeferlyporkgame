extends RefCounted
## Trade prices, shops, taverns and settlement income.

const Roster = preload("res://scripts/core/roster.gd")

static func local_production(sid: String) -> Array:
	var d: Dictionary = Data.settlements[sid]
	var out: Array = d.produces.duplicate()
	if d.type == "town" or d.type == "castle":
		for vid in Data.settlements:
			var v: Dictionary = Data.settlements[vid]
			if v.get("bound", "") == sid:
				for g in v.produces:
					if not out.has(g):
						out.append(g)
	return out

static func target_mult(sid: String, good: String) -> float:
	var prod := local_production(sid)
	var d: Dictionary = Data.settlements[sid]
	var m := 1.2
	if prod.has(good):
		m = 0.65 if d.type != "village" else 0.6
	elif Data.goods[good].food:
		m = 1.1
	# Polar settlements pay more for southern luxuries
	if d.culture in ["north", "south"] and good in ["tea", "silk", "rice", "spices"]:
		m += 0.35
	if d.culture == "fire" and good in ["jade"]:
		m += 0.25
	if d.culture == "earth" and good in ["fire_flakes", "whale_oil"]:
		m += 0.2
	var pr: float = GS.settlements[sid].prosperity
	m *= 1.1 - pr / 500.0
	return m

static func init_prices() -> void:
	for sid in GS.settlements:
		if Data.settlements[sid].type in ["ruin"]:
			continue
		for g in Data.goods:
			GS.settlements[sid].prices[g] = target_mult(sid, g) * randf_range(0.9, 1.1)

static func daily_update() -> void:
	for sid in GS.settlements:
		var s: Dictionary = GS.settlements[sid]
		if Data.settlements[sid].type == "ruin":
			continue
		for g in Data.goods:
			var t := target_mult(sid, g)
			var m: float = s.prices.get(g, 1.0)
			m += (t - m) * 0.08 + randf_range(-0.02, 0.02)
			s.prices[g] = clampf(m, 0.35, 3.0)

## Goods traded at a settlement's market.
static func market_goods(sid: String) -> Array:
	var d: Dictionary = Data.settlements[sid]
	if d.type == "town":
		return Data.goods.keys()
	if d.type == "village":
		var out: Array = d.produces.duplicate()
		for g in ["rice", "fish", "cabbages"]:
			if not out.has(g) and not (d.culture in ["north", "south"] and g == "rice"):
				out.append(g)
		if d.culture in ["north", "south"] and not out.has("seal_jerky"):
			out.append("seal_jerky")
		return out
	if d.type == "temple":
		# The Nomads are vegetarian: no fish, no jerky
		var tg: Array = d.produces.duplicate()
		for g in ["rice", "cabbages", "sea_prunes"]:
			if not tg.has(g):
				tg.append(g)
		return tg
	return []

static func buy_price(sid: String, good: String) -> int:
	var m: float = GS.settlements[sid].prices.get(good, 1.0)
	var spread := 1.08 - GS.skill("trade") * 0.008
	return maxi(1, int(round(Data.goods[good].price * m * spread)))

static func sell_price(sid: String, good: String) -> int:
	var m: float = GS.settlements[sid].prices.get(good, 1.0)
	var spread := 0.88 + GS.skill("trade") * 0.01
	return maxi(1, int(round(Data.goods[good].price * m * spread)))

static func buy(sid: String, good: String) -> bool:
	var p := buy_price(sid, good)
	if GS.player.gold < p:
		return false
	GS.add_gold(-p)
	GS.add_good(good, 1)
	GS.settlements[sid].prices[good] = minf(3.0, GS.settlements[sid].prices[good] * 1.025)
	return true

static func sell(sid: String, good: String) -> bool:
	if int(GS.player.goods.get(good, 0)) <= 0:
		return false
	var p := sell_price(sid, good)
	GS.add_gold(p)
	GS.add_good(good, -1)
	GS.settlements[sid].prices[good] = maxf(0.35, GS.settlements[sid].prices[good] * 0.975)
	GS.settlements[sid].prosperity = minf(100.0, GS.settlements[sid].prosperity + 0.05)
	return true

# ---------------------------------------------------------------------------
# Equipment shops
# ---------------------------------------------------------------------------
static func shop_items(sid: String) -> Array:
	var s: Dictionary = GS.settlements[sid]
	if not s.has("shop") or GS.day() - int(s.get("shop_day", -99)) >= 7:
		var culture: String = Data.settlements[sid].culture
		var pool: Array = Data.culture_shop.get(culture, Data.culture_shop.earth).duplicate()
		pool.shuffle()
		var n := mini(pool.size(), 7 + randi() % 4)
		s.shop = pool.slice(0, n)
		if sid == "fire_fountain" and randf() < 0.5:
			s.shop.append("space_sword")
		s.shop_day = GS.day()
	return s.shop

static func item_buy_price(id: String) -> int:
	return int(Data.item(id).price * (1.1 - GS.skill("trade") * 0.01))

static func item_sell_price(id: String) -> int:
	return int(Data.item(id).price * (0.4 + GS.skill("trade") * 0.015))

# ---------------------------------------------------------------------------
# Taverns
# ---------------------------------------------------------------------------
static func refresh_tavern(sid: String) -> void:
	var d: Dictionary = Data.settlements[sid]
	if d.type != "town":
		return
	var t := {}
	if randf() < 0.75:
		var merc: String = ["merc_swordsman", "merc_archer", "rough_rhino", "merc_swordsman", "red_lantern"].pick_random()
		var n := 3 + randi() % 8
		if merc == "rough_rhino":
			n = 2 + randi() % 4
		t.merc = {"id": merc, "n": n}
	t.ransom = randf() < 0.6
	t.rumor = Data.rumors.pick_random()
	# A wandering companion
	var free := []
	for cid in Data.companions:
		if GS.player.is_empty() or not GS.player.companions.has(cid):
			var elsewhere := false
			for other in GS.settlements:
				if other != sid and GS.settlements[other].tavern.get("companion", "") == cid:
					elsewhere = true
			if not elsewhere:
				free.append(cid)
	if not free.is_empty() and randf() < 0.45:
		t.companion = free.pick_random()
	GS.settlements[sid].tavern = t

static func merc_cost(id: String) -> int:
	return 20 + Data.troop_upgrade_cost(id) + Data.troop(id).tier * 25

static func ransom_value(id: String) -> int:
	return 10 + Data.troop(id).tier * Data.troop(id).tier * 12

# ---------------------------------------------------------------------------
# Recruiting
# ---------------------------------------------------------------------------
static func recruit_cost(sid: String) -> int:
	return 10 + (0 if GS.settlements[sid].relation > 10 else 5)

static func recruit_troop(sid: String) -> String:
	return Data.culture_recruit.get(Data.settlements[sid].culture, "ek_peasant")

## Weekly income from fiefs owned by the player.
static func fief_income() -> int:
	var total := 0
	for sid in GS.settlements:
		var s: Dictionary = GS.settlements[sid]
		if s.owner != "player":
			continue
		var d: Dictionary = Data.settlements[sid]
		var base := 0.0
		match d.type:
			"village": base = 120.0
			"castle": base = 150.0
			"town": base = 450.0
		if s.looted_until > GS.hours:
			base *= 0.2
		total += int(base * (0.5 + s.prosperity / 100.0))
	return total

static func garrison_wages() -> int:
	var total := 0
	for sid in GS.settlements:
		if GS.settlements[sid].owner == "player":
			total += int(Roster.wages(GS.settlements[sid].garrison) * 0.5)
	return total
