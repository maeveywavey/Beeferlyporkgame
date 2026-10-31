extends Node3D
## TASK 16 fire placeholder: unlit orange squares, 50% opacity, billboarded.
## Each square is born at the emitter's origin (its bottom edge on the source),
## moves with its velocity, and shrinks linearly to nothing over its life. No
## texture, no glow. A MultiMesh draws every live square in one call.
## Particle positions are local to this node: parent the emitter to whatever
## the fire is attached to (a unit, a projectile, the field) and it follows.

const COLOR := Color(1.0, 0.5, 0.12, 0.5)

static var _mesh: QuadMesh

## Particles per second while spawning (0 = none; see `add`).
var rate := 0.0
## Seconds after creation that spawning stops (0 = spawn until `stop()`).
var duration := 0.0
## Square side at birth, metres.
var size := 0.4
## Lifetime of a square, seconds.
var life := 1.0
## Upward speed at birth, m/s (ground fire and burning bodies).
var rise := 1.2
## Radius of the spawn disc, metres.
var spread := 0.3
## Horizontal velocity jitter at birth, m/s.
var drift := 0.1

var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _age := PackedFloat32Array()
var _life := PackedFloat32Array()
var _size := PackedFloat32Array()
var _acc := 0.0
var _t := 0.0
var _mmi: MultiMeshInstance3D

func _ready() -> void:
	if _mesh == null:
		_mesh = QuadMesh.new()
		_mesh.size = Vector2.ONE
		# the square's bottom edge sits on the particle's position
		_mesh.center_offset = Vector3(0, 0.5, 0)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = COLOR
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mesh.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _mesh
	mm.instance_count = 16
	mm.visible_instance_count = 0
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = mm
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mmi)

## Stop spawning; the node frees itself once its last square is gone.
func stop() -> void:
	rate = 0.0
	duration = _t

## Add one square with an explicit start and velocity (local space).
func add(pos: Vector3, vel: Vector3, sz: float, lt: float) -> void:
	_pos.append(pos)
	_vel.append(vel)
	_age.append(0.0)
	_life.append(maxf(lt, 0.05))
	_size.append(maxf(sz, 0.01))

func _spawn() -> void:
	var a := randf() * TAU
	var r := spread * sqrt(randf())
	var v := Vector3(randf_range(-drift, drift), rise * randf_range(0.8, 1.2), randf_range(-drift, drift))
	add(Vector3(cos(a) * r, 0.0, sin(a) * r), v, size * randf_range(0.8, 1.2), life * randf_range(0.8, 1.15))

func _process(delta: float) -> void:
	_t += delta
	if rate > 0.0 and (duration <= 0.0 or _t < duration):
		_acc += rate * delta
		while _acc >= 1.0:
			_acc -= 1.0
			_spawn()
	var i := _pos.size() - 1
	while i >= 0:
		_age[i] += delta
		if _age[i] >= _life[i]:
			_pos.remove_at(i)
			_vel.remove_at(i)
			_age.remove_at(i)
			_life.remove_at(i)
			_size.remove_at(i)
		else:
			_pos[i] += _vel[i] * delta
			# jets lose their push; rising squares keep a slight lift
			_vel[i] *= maxf(0.0, 1.0 - 1.6 * delta)
		i -= 1
	var mm := _mmi.multimesh
	var n := _pos.size()
	if n > mm.instance_count:
		mm.instance_count = maxi(n, mm.instance_count * 2)
	# billboard on the CPU: a material billboard would drop the per-square scale
	var cam: Camera3D = get_viewport().get_camera_3d()
	var face: Basis = Basis()
	var gb: Basis = global_transform.basis
	if cam != null and absf(gb.determinant()) > 1e-4:
		face = gb.inverse() * cam.global_transform.basis
	for k in n:
		var f := _age[k] / _life[k]
		var s := _size[k] * (1.0 - f)
		var b := Basis(face.x * s, face.y * s, face.z)
		mm.set_instance_transform(k, Transform3D(b, _pos[k]))
	mm.visible_instance_count = n
	if n == 0 and rate <= 0.0 and _t > 0.0:
		queue_free()
