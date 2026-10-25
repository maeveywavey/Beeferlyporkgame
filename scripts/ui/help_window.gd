extends "res://scripts/ui/window_base.gd"
## How-to-play guide, shown at the start of a new game and from the camp menu.

var map
var tab := 0

const PAGES := [
	["Getting started", """[b]Welcome to the world of Avatar.[/b] The Hundred Year War rages on, and you start with a handful of followers and a little gold.

[b]Travel[/b] by left-clicking the map. Time passes only while you travel or wait. Click a town to visit it, or a party to approach it. Scroll to zoom, right-drag to rotate, and press F to re-centre on your party.

[b]Your first days[/b]
• Buy [b]food[/b] at a market. Your party eats every day, and the top bar shows how many days of food you have left.
• Recruit [b]volunteers[/b] in villages and hire [b]mercenaries[/b] in town taverns.
• Ask village elders and guild masters for [b]work[/b]. Quests pay well and earn you friends.
• Hunt small bandit groups to gain experience, gold and prisoners. Sell prisoners to tavern ransom brokers.
• Spend attribute and skill points in the Character screen (C), and upgrade troops in the Party screen (P)."""],
	["Battles", """When you meet hostile troops you can [b]charge[/b] (fight the battle yourself), [b]send your troops[/b] (auto-resolve), or try to leave.

[b]Combat[/b]
• WASD to move, mouse to look, left mouse to attack, right mouse to block.
• Your attack direction follows your last mouse movement: up for an overhead strike, down for a thrust, left or right for a swing.
• Press 2 for your bow or boomerang (hold to draw, release to shoot) and 1 to return to melee.
• Order your troops with F1 (hold), F2 (follow) and F3 (charge).

[b]Bending[/b] (Q / E / R) uses chi, the blue bar.
• Fire: Fire Blast, Fire Wave, Lightning (needs Bending skill 5)
• Earth: Rock Throw, Earth Wall, Earthquake
• Water: Water Whip, Healing Water, Ice Spikes

Firebenders are strongest by day, waterbenders at night and under a full moon. Solar eclipses take firebending away while the sun is dark; lunar eclipses do the same to waterbending. A passing comet makes fire burn hotter. The sages announce each one five days ahead — plan around them."""],
	["Rising in the world", """[b]Renown[/b] grows with every victory. It enlarges your party and opens doors.

• Talk to any lord to become a [b]mercenary[/b] for their nation, with weekly pay.
• With 150 renown, pledge yourself to a king as a [b]vassal[/b] and receive a village.
• [b]Besiege[/b] enemy castles and towns. After 12 hours your ladders are ready, and you storm the walls through the breach.
• Garrison captured fiefs with troops from your party. Fiefs pay taxes every week.

[b]Places of note[/b]
• Gaoling's [b]Stone Pit[/b]: five fights, ending with the champion they call the Quiet Mountain.
• The four [b]Air Temples[/b] cannot be attacked. Rest there for free, and the monks tend your wounded.
• Wan Shi Tong's Library and the Ruins of Taku hold one-time rewards for explorers.
• Air Nomad pilgrims fly the world on sky bison. They never fight, and they will heal your wounded."""],
]

func _init() -> void:
	window_size = Vector2(860, 600)

func build() -> void:
	set_title("How to Play")
	var tabs := UI.hbox()
	content.add_child(tabs)
	for i in PAGES.size():
		var b := UI.button(PAGES[i][0], func():
			tab = i
			refresh())
		if i == tab:
			b.add_theme_color_override("font_color", UI.GOLD)
		tabs.add_child(b)
	var sc := UI.scroll(440)
	content.add_child(sc)
	var r := UI.rich(PAGES[tab][1], 780)
	sc.add_child(r)
	var row := UI.hbox()
	content.add_child(row)
	row.add_child(UI.expand())
	if tab < PAGES.size() - 1:
		row.add_child(UI.button("Next", func():
			tab += 1
			refresh(), 120))
	row.add_child(UI.button("Close", close, 120))
