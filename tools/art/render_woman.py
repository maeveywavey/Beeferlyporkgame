"""Stage 3: texture the woman and render review shots.

blender -b <workdir>/woman.blend --python tools/art/render_woman.py -- <workdir>

Shots: a turnaround at rest, a close-up of the head, a stride (one leg
forward, one back with the knee bent) from the front-quarter and the side,
and a reach (arm raised, arm lowered) to check the shoulders. Textures are
point-sampled and unlit apart from the light painted into them, as on a
PlayStation.
"""
import bpy
import math
import os
import sys

work = sys.argv[sys.argv.index("--") + 1]
shots = os.path.join(work, "shots")
os.makedirs(shots, exist_ok=True)
rig = bpy.data.objects["Rig"]
PAGES = {"BodyVisible": "Body", "Outfit": "Outfit", "Hair": "Hair"}

for oname, page in PAGES.items():
    ob = bpy.data.objects[oname]
    mat = bpy.data.materials.new(oname + "_mat")
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.join(work, f"{page}_tex.png"))
    tex.interpolation = "Closest"
    em = nt.nodes.new("ShaderNodeEmission")
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(tex.outputs[0], em.inputs[0])
    nt.links.new(em.outputs[0], out.inputs[0])
    mat.use_backface_culling = False
    ob.data.materials.clear()
    ob.data.materials.append(mat)
    ob.hide_render = False
for o in bpy.data.objects:
    if o.type == "MESH" and o.name not in PAGES:
        o.hide_render = True

sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "FLAT"
sc.display.shading.color_type = "TEXTURE"
sc.display.shading.show_object_outline = False
sc.view_settings.view_transform = "Standard"
sc.world.color = (0.16, 0.16, 0.17)
cam = bpy.data.cameras.new("Cam")
co = bpy.data.objects.new("Cam", cam)
sc.collection.objects.link(co)
sc.camera = co
cam.type = "ORTHO"


def shoot(name, yaw, target, scale, res=(900, 1200), pitch=0.0):
    r, p = math.radians(yaw), math.radians(pitch)
    d = 6.0
    co.location = (target[0] + math.sin(r) * d * math.cos(p), target[1] - math.cos(r) * d * math.cos(p), target[2] + math.sin(p) * d)
    co.rotation_euler = (math.radians(90) - p, 0, r)
    cam.ortho_scale = scale
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.filepath = os.path.join(shots, name + ".png")
    bpy.ops.render.render(write_still=True)


def pose(rots):
    for pb in rig.pose.bones:
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = (0, 0, 0)
    for bname, (rx, ry, rz) in rots.items():
        rig.pose.bones[bname].rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
    bpy.context.view_layer.update()


REST = {}
pose(REST)
for i, yaw in enumerate((0, 35, 90, 180, 215)):
    shoot(f"turn_{i}", yaw, (0, 0, 0.92), 2.0, (700, 1100))
shoot("head_front", 0, (0, -0.02, 1.64), 0.36, (700, 700))
shoot("head_q", 35, (0, -0.02, 1.64), 0.36, (700, 700))
shoot("head_back", 160, (0, 0.0, 1.66), 0.36, (700, 700))

STRIDE = {"UpperLeg.L": (-38, 0, 0), "LowerLeg.L": (12, 0, 0), "UpperLeg.R": (28, 0, 0), "LowerLeg.R": (48, 0, 0),
          "Foot.R": (-20, 0, 0), "UpperArm.L": (0, 0, -40), "UpperArm.R": (0, 0, 40), "Hips": (0, 6, 0)}
pose(STRIDE)
shoot("stride_q", 35, (0, 0, 0.8), 1.8, (900, 1100))
shoot("stride_side", 90, (0, 0, 0.8), 1.8, (900, 1100))
shoot("stride_front", 0, (0, 0, 0.8), 1.8, (900, 1100))

REACH = {"UpperArm.L": (0, 0, 70), "LowerArm.L": (0, 0, 30), "UpperArm.R": (0, 0, 45), "LowerArm.R": (-40, 0, 0)}
pose(REACH)
shoot("reach_front", 0, (0, 0, 1.2), 1.5, (1100, 1000))
shoot("reach_back", 180, (0, 0, 1.2), 1.5, (1100, 1000))
print("RENDERED")
