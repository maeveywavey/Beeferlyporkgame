extends "res://scripts/ui/window_base.gd"
## The ending of The Drowned Testament: what became of the world and of the
## people you travelled with. The game continues afterwards.

const Endings = preload("res://scripts/story/endings.gd")

var map
var kind := ""

func _init() -> void:
	window_size = Vector2(980, 640)

func build() -> void:
	set_title({"told": "The Truth Told", "sold_fire": "The Truth Sold", "sold_earth": "The Truth Sold",
		"sold_omashu": "The Truth Sold", "buried": "The Truth Buried", "burned": "The Truth Burned", "kept": "The Truth Kept"}.get(kind, "Epilogue"))
	var sc := UI.scroll(500)
	content.add_child(sc)
	sc.add_child(UI.rich(Endings.epilogue_text(kind), 920))
	var b := UI.hbox()
	content.add_child(b)
	b.add_child(UI.rich("[i]The story of the Drowned Testament is over. The world goes on — and so can you.[/i]", 700))
	b.add_child(UI.expand())
	b.add_child(UI.button("Continue", close, 140))
