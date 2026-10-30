extends "res://scripts/ui/window_base.gd"
## Battle aftermath summary.

var map
var result := {}

func _init() -> void:
	window_size = Vector2(720, 480)

## Size the sheet to what it has to say: a short defeat is a short note.
func _ready() -> void:
	var rows: int = result.get("lines", []).size()
	for k in ["prisoners", "goods", "items"]:
		if not result.get(k, []).is_empty():
			rows += 2
	window_size = Vector2(720, clampf(190.0 + rows * 34.0, 240.0, 480.0))
	super()

func build() -> void:
	var won: bool = result.get("won", false)
	set_title("Victory!" if won else "Defeat")
	var lines: Array = result.get("lines", [])
	content.add_child(UI.rich("\n".join(lines), 660))
	var pris: Array = result.get("prisoners", [])
	if not pris.is_empty():
		var parts := []
		for p in pris:
			parts.append("%d %s" % [p[1], Data.troop(p[0]).name])
		content.add_child(UI.rich("Prisoners taken: " + ", ".join(parts), 660))
	var goods: Dictionary = result.get("goods", {})
	if not goods.is_empty():
		var gp := []
		for g in goods:
			gp.append("%d %s" % [goods[g], Data.goods[g].name])
		content.add_child(UI.rich("Plunder: " + ", ".join(gp), 660))
	var items: Array = result.get("items", [])
	if not items.is_empty():
		var ip := []
		for it in items:
			ip.append(Data.item(it).name)
		content.add_child(UI.rich("Equipment taken: " + ", ".join(ip) + " (see Inventory)", 660))
	if not won and GS.player.get("captive_until", -1.0) > GS.hours:
		content.add_child(UI.rich("[i]You are dragged away in chains. Time will pass until you find a chance to escape.[/i]", 660))
	content.add_child(UI.spacer(10))
	var b := UI.hbox()
	content.add_child(b)
	b.add_child(UI.expand())
	b.add_child(UI.button("Continue", close, 140))
