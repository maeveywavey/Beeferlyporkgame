extends RefCounted
## Static helpers operating on a troop roster.
## A roster is an Array of stacks: {"id": String, "n": int, "w": int, "xp": int}
## "n" is the total count, "w" how many of those are wounded.

static func find(roster: Array, id: String) -> Dictionary:
	for s in roster:
		if s.id == id:
			return s
	return {}

static func add(roster: Array, id: String, count: int, wounded: int = 0) -> void:
	if count <= 0:
		return
	var s := find(roster, id)
	if s.is_empty():
		roster.append({"id": id, "n": count, "w": wounded, "xp": 0})
	else:
		s.n += count
		s.w += wounded

## Remove up to `count` troops of a type, preferring healthy ones unless
## `wounded_first`. Returns how many were removed.
static func remove(roster: Array, id: String, count: int, wounded_first: bool = false) -> int:
	var s := find(roster, id)
	if s.is_empty():
		return 0
	var r: int = mini(count, s.n)
	if wounded_first:
		var rw: int = mini(r, s.w)
		s.w -= rw
	else:
		var healthy: int = s.n - s.w
		var from_wounded: int = maxi(0, r - healthy)
		s.w -= from_wounded
	s.n -= r
	s.w = clampi(s.w, 0, s.n)
	if s.n <= 0:
		roster.erase(s)
	return r

static func wound(roster: Array, id: String, count: int) -> void:
	var s := find(roster, id)
	if s.is_empty():
		return
	s.w = mini(s.n, s.w + count)

static func total(roster: Array) -> int:
	var t := 0
	for s in roster:
		t += s.n
	return t

static func healthy(roster: Array) -> int:
	var t := 0
	for s in roster:
		t += s.n - s.w
	return t

static func wounded(roster: Array) -> int:
	var t := 0
	for s in roster:
		t += s.w
	return t

static func power(roster: Array, healthy_only: bool = true) -> float:
	var p := 0.0
	for s in roster:
		var n: int = (s.n - s.w) if healthy_only else s.n
		p += Data.troop_power(s.id) * n
	return p

static func wages(roster: Array) -> int:
	var w := 0
	for s in roster:
		w += Data.troop_wage(s.id) * s.n
	return w

static func count_mounted(roster: Array) -> int:
	var c := 0
	for s in roster:
		if Data.troop(s.id).mount != "":
			c += s.n
	return c

static func count_healers(roster: Array) -> int:
	var c := 0
	for s in roster:
		if Data.troop(s.id).healer:
			c += s.n - s.w
	return c

static func heal(roster: Array, count: int) -> void:
	var left := count
	for s in roster:
		if left <= 0:
			return
		var h: int = mini(left, s.w)
		s.w -= h
		left -= h

## Heal a fraction of each stack's wounded, rounding probabilistically.
static func heal_fraction(roster: Array, frac: float) -> void:
	for s in roster:
		if s.w <= 0:
			continue
		var exact: float = s.w * frac
		var h := int(exact)
		if randf() < exact - h:
			h += 1
		s.w = maxi(0, s.w - h)

## Expand a roster into a flat list of troop ids (healthy only).
static func expand(roster: Array, healthy_only: bool = true) -> Array:
	var out := []
	for s in roster:
		var n: int = (s.n - s.w) if healthy_only else s.n
		for i in n:
			out.append(s.id)
	return out

## Pick a random troop id weighted by count.
static func random_troop(roster: Array, healthy_only: bool = true) -> String:
	var t := healthy(roster) if healthy_only else total(roster)
	if t <= 0:
		return ""
	var r := randi() % t
	for s in roster:
		var n: int = (s.n - s.w) if healthy_only else s.n
		if r < n:
			return s.id
		r -= n
	return ""

static func duplicate_roster(roster: Array) -> Array:
	return roster.duplicate(true)

static func sort_by_tier(roster: Array) -> void:
	roster.sort_custom(func(a, b): return Data.troop(a.id).tier > Data.troop(b.id).tier)

## Add XP to every stack and return the list of stack ids that can upgrade.
static func give_xp(roster: Array, xp_each: int) -> void:
	for s in roster:
		var need := Data.troop_xp_needed(s.id)
		var cap: int = need * s.n
		s.xp = mini(cap, s.xp + xp_each * s.n)

static func upgradable_count(stack: Dictionary) -> int:
	if Data.troop_upgrades(stack.id).is_empty():
		return 0
	var need := Data.troop_xp_needed(stack.id)
	if need <= 0:
		return 0
	return mini(stack.n - stack.w, int(stack.xp / need))

## Upgrade `count` troops of stack id into target. Caller pays gold.
static func upgrade(roster: Array, id: String, target: String, count: int) -> int:
	var s := find(roster, id)
	if s.is_empty():
		return 0
	var can := upgradable_count(s)
	var n := mini(count, can)
	if n <= 0:
		return 0
	var need := Data.troop_xp_needed(id)
	s.xp -= need * n
	remove(roster, id, n)
	add(roster, target, n)
	return n
