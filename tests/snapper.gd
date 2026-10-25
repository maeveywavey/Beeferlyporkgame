extends Node
## Waits, then saves a screenshot and quits. Lives under the root so it
## survives scene changes.
var out := ""
var secs := 2.0
var actions: Array = []

func _ready() -> void:
	for a in actions:
		await get_tree().create_timer(a[0]).timeout
		a[1].call()
	await get_tree().create_timer(secs).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
