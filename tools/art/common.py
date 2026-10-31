"""Shared helpers for the Blender art scripts (run inside Blender).

Coordinates follow the owner's base mesh: metres, Z up, the character faces
-Y, the character's left is +X, feet at Z = 0, height 1.80 m, A-pose.
"""
import bpy
import bmesh
import math
from mathutils import Vector

# Joint positions of the base mesh (A-pose). Arms are given for +X and
# mirrored. Measured from the vertex layout of humanoid_base.blend, then the
# arm joints are swung up by raise_arm() (build_base.py does the same to the
# arm's vertices).
J = {
    "root": Vector((0, 0, 0)),
    "hips": Vector((0, 0.0, 0.93)),
    "spine": Vector((0, 0.0, 1.08)),
    "chest": Vector((0, 0.0, 1.26)),
    "neck": Vector((0, 0.0, 1.45)),
    "head": Vector((0, -0.01, 1.53)),
    "head_top": Vector((0, -0.02, 1.81)),
    "clavicle": Vector((0.04, 0.0, 1.40)),
    "shoulder": Vector((0.20, 0.01, 1.39)),
    "elbow": Vector((0.43, 0.02, 1.27)),
    "wrist": Vector((0.65, 0.01, 1.12)),
    "hand_end": Vector((0.80, 0.0, 1.02)),
    "thigh": Vector((0.10, 0.0, 0.92)),
    "knee": Vector((0.125, -0.01, 0.51)),
    "ankle": Vector((0.16, 0.0, 0.08)),
    "toe": Vector((0.17, -0.17, 0.02)),
}


# The arms sit higher in the socket than in the source mesh: each arm is
# swung up about the shoulder joint by ARM_RAISE_DEG.
ARM_RAISE_DEG = 8.0
SHOULDER_PIVOT = Vector((0.20, 0.01, 1.39))


def raise_arm(v: Vector, amount: float = 1.0) -> Vector:
    sgn = 1.0 if v.x >= 0 else -1.0
    piv = Vector((SHOULDER_PIVOT.x * sgn, SHOULDER_PIVOT.y, SHOULDER_PIVOT.z))
    a = math.radians(ARM_RAISE_DEG) * amount * sgn
    d = v - piv
    return piv + Vector((d.x * math.cos(a) - d.z * math.sin(a), d.y, d.x * math.sin(a) + d.z * math.cos(a)))


for _k in ("elbow", "wrist", "hand_end"):
    J[_k] = raise_arm(J[_k])


def mirror(v: Vector) -> Vector:
    return Vector((-v.x, v.y, v.z))


def side_joint(name: str, s: str) -> Vector:
    return J[name] if s == "L" else mirror(J[name])


# Bones: name -> (head joint, tail joint, parent, side or None)
BONES = [
    ("Hips", "hips", "spine", None, None),
    ("Spine", "spine", "chest", "Hips", None),
    ("Chest", "chest", "neck", "Spine", None),
    ("Neck", "neck", "head", "Chest", None),
    ("Head", "head", "head_top", "Neck", None),
]
for _s in ("L", "R"):
    BONES += [
        ("Clavicle." + _s, "clavicle", "shoulder", "Chest", _s),
        ("UpperArm." + _s, "shoulder", "elbow", "Clavicle." + _s, _s),
        ("LowerArm." + _s, "elbow", "wrist", "UpperArm." + _s, _s),
        ("Hand." + _s, "wrist", "hand_end", "LowerArm." + _s, _s),
        ("UpperLeg." + _s, "thigh", "knee", "Hips", _s),
        ("LowerLeg." + _s, "knee", "ankle", "UpperLeg." + _s, _s),
        ("Foot." + _s, "ankle", "toe", "LowerLeg." + _s, _s),
    ]


def joint(name: str, side) -> Vector:
    return side_joint(name, side) if side else J[name].copy()


def build_armature(name="Rig"):
    arm = bpy.data.armatures.new(name)
    ob = bpy.data.objects.new(name, arm)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    for bname, h, t, parent, side in BONES:
        eb = arm.edit_bones.new(bname)
        eb.head = joint(h, side)
        eb.tail = joint(t, side)
        if parent:
            eb.parent = arm.edit_bones[parent]
            eb.use_connect = (eb.parent.tail - eb.head).length < 1e-4
        eb.roll = 0.0
    bpy.ops.object.mode_set(mode="OBJECT")
    return ob


def seg_point(p: Vector, a: Vector, b: Vector) -> Vector:
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return a + ab * t


def smooth(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)


def region_of(c: Vector) -> str:
    """Body region of a point (face centre) on the base mesh."""
    ax = abs(c.x)
    if c.z > 1.53 or (c.z > 1.475 and ax < 0.07):
        return "head"
    if ax > 0.215 and c.z > 0.98:
        if ax > 0.645:
            return "hand"
        if ax > 0.43:
            return "forearm"
        return "upperarm"
    if c.z > 0.88:
        return "torso"
    if c.z > 0.50:
        return "thigh"
    if c.z > 0.09:
        return "shin"
    return "foot"


def render_setup(res=(1600, 900), ortho=2.1, bg=(0.17, 0.17, 0.18)):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE_NEXT"
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.film_transparent = False
    world = sc.world or bpy.data.worlds.new("W")
    sc.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (*bg, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    sc.view_settings.view_transform = "Standard"
    cam = bpy.data.cameras.new("Cam")
    co = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(co)
    sc.camera = co
    cam.type = "ORTHO"
    cam.ortho_scale = ortho
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 2.5
    so = bpy.data.objects.new("Sun", sun)
    sc.collection.objects.link(so)
    so.rotation_euler = (math.radians(50), math.radians(10), math.radians(-30))
    return co


def aim_camera(co, yaw_deg, target=(0, 0, 0.9), dist=6.0, pitch_deg=0.0):
    r = math.radians(yaw_deg)
    p = math.radians(pitch_deg)
    tx, ty, tz = target
    co.location = (tx + math.sin(r) * dist * math.cos(p), ty - math.cos(r) * dist * math.cos(p), tz + math.sin(p) * dist)
    co.rotation_euler = (math.radians(90) - p, 0, r)
