extends RefCounted
## Hand-inked flipbook fire: flat-colour flame sprites on billboards, in the
## manner of the animated series (assets/fx, drawn by tools/paint_flames.py).
## Every fire in a battle (ground fires, fireballs, jets of flame, people
## burning, embers of the dead) uses these instead of blurred particles.

const SHADER = preload("res://shaders/flame_sprite.gdshader")
const SHEETS := {
	"flame": ["res://assets/fx/flame.png", "res://assets/fx/flame_blue.png", 8, 12.0],
	"fireball": ["res://assets/fx/fireball.png", "res://assets/fx/fireball_blue.png", 8, 14.0],
	"smoke": ["res://assets/fx/smoke.png", "res://assets/fx/smoke.png", 6, 6.0],
}
static var _tex := {}
const BURY := 0.16

static func _texture(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path)
	return _tex[path]

## One sprite. `kind` is "flame" (upright, base at the node), "fireball"
## (centred, tail trailing) or "smoke". `billboard` as in the shader.
static func make(kind: String, size: Vector2, blue: bool = false, billboard: int = 1) -> MeshInstance3D:
	var spec: Array = SHEETS[kind]
	var qm := QuadMesh.new()
	qm.size = size
	if kind != "fireball":
		# the bottom 16% of a flame sprite sinks below its anchor: buried in the
		# ground (or the body that burns), so its lower edge is never seen
		qm.center_offset = Vector3(0, size.y * 0.5 - size.y * BURY, 0)
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("sheet", _texture(spec[1] if blue else spec[0]))
	m.set_shader_parameter("frames", spec[2])
	m.set_shader_parameter("fps", spec[3])
	m.set_shader_parameter("phase", randf() * float(spec[2]))
	m.set_shader_parameter("billboard", billboard)
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

## A flame that burns for `life` seconds, shrinking away at the end, then frees itself.
static func puff(parent: Node, pos: Vector3, size: Vector2, life: float, blue: bool = false) -> MeshInstance3D:
	var s := make("flame", size, blue, 1)
	parent.add_child(s)
	s.global_position = pos
	var tw := s.create_tween()
	tw.tween_interval(maxf(0.05, life * 0.6))
	tw.tween_property(s, "scale", Vector3(0.05, 0.05, 0.05), life * 0.4)
	tw.tween_callback(s.queue_free)
	return s

## A jet of flame thrown from `origin` along `yaw`: a spray of tongues that
## fly out, flicker and die.
static func jet(parent: Node, origin: Vector3, yaw: float, reach: float, spread_deg: float, blue: bool = false, count: int = 14, life: float = 0.55) -> void:
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	for i in count:
		var a := deg_to_rad(randf_range(-spread_deg, spread_deg) * 0.5)
		var d := fwd.rotated(Vector3.UP, a)
		var dist := reach * randf_range(0.45, 1.0)
		var sz := randf_range(0.9, 1.5)
		# airborne flame is drawn as comet-like fireballs (no flat base to show)
		var s := make("fireball", Vector2(sz * 1.6, sz * 1.6), blue, 3)
		parent.add_child(s)
		s.global_position = origin
		s.basis = Basis.looking_at(-d, Vector3.UP)
		s.scale = Vector3.ONE * 0.4
		var lt := life * randf_range(0.7, 1.1)
		var tw := s.create_tween()
		tw.set_parallel(true)
		tw.tween_property(s, "global_position", origin + d * dist + Vector3(0, randf_range(-0.2, 0.5), 0), lt * 0.8).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "scale", Vector3.ONE, lt * 0.35)
		tw.chain().tween_property(s, "scale", Vector3(0.05, 0.05, 0.05), lt * 0.4)
		tw.chain().tween_callback(s.queue_free)
