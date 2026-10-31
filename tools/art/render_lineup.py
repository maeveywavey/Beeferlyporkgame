"""Render the body-shape lineup: one figure per blend shape and some mixes.

blender -b <body.blend> --python tools/art/render_lineup.py -- <out.png>
"""
import bpy
import sys
import os
import math

sys.path.insert(0, os.path.dirname(__file__))
import common as C

out = sys.argv[sys.argv.index("--") + 1]
body = bpy.data.objects["Body"]
rig = bpy.data.objects["Rig"]
rig.hide_render = True

FIGS = [
    ("Base", {}), ("Tall", {"Tall": 1}), ("Short", {"Short": 1}), ("Thin", {"Thin": 1}),
    ("Heavy", {"Heavy": 1}), ("Muscular", {"Muscular": 1}), ("Feminine", {"Feminine": 1}), ("Thin fem", {"Feminine": 1, "Thin": 1}), ("Heavy fem", {"Feminine": 1, "Heavy": 1}),
    ("Curvy", {"Feminine": 1, "Curvy": 1}), ("Flat", {"Feminine": 1, "Flat": 1}),
    ("Child", {"Child": 1}), ("Teen", {"Teen": 1}), ("Elder", {"Elder": 1}),
    ("Brawny tall", {"Muscular": 1, "Heavy": 0.4, "Tall": 1}),
    ("Elder heavy woman", {"Elder": 1, "Feminine": 1, "Heavy": 0.6}),
    ("Thin teen girl", {"Teen": 1, "Feminine": 1, "Thin": 0.6}),
    ("Heavy x2", {"Heavy": 1, "HeavyMore": 1}),
    ("Curvy x2", {"Feminine": 1, "Curvy": 1, "CurvyMore": 1}),
    ("Fem+Heavy x2", {"Feminine": 1, "FeminineMore": 1, "Heavy": 1, "HeavyMore": 1}),
    ("Curvy x2 heavy", {"Feminine": 1, "Curvy": 1, "CurvyMore": 1, "Heavy": 1}),
]

# optional: a subset by label, and a yaw: -- out.png "Base,Curvy x2" 35
argv = sys.argv[sys.argv.index("--") + 1:]
if len(argv) > 1 and argv[1]:
    want = argv[1].split(",")
    FIGS = [f for f in FIGS if f[0] in want]
YAW = float(argv[2]) if len(argv) > 2 else -20.0
for k in body.data.shape_keys.key_blocks:
    k.value = 0.0
dg = bpy.context.evaluated_depsgraph_get()
step = 0.75 if len(FIGS) > 8 else 1.1
for i, (label, mix) in enumerate(FIGS):
    for k in body.data.shape_keys.key_blocks:
        k.value = mix.get(k.name, 0.0)
    dg.update()
    m = bpy.data.meshes.new_from_object(body.evaluated_get(dg))
    ob = bpy.data.objects.new("fig_" + label, m)
    bpy.context.scene.collection.objects.link(ob)
    ob.location.x = (i - (len(FIGS) - 1) / 2) * step
    ob.rotation_euler.z = math.radians(YAW)
    t = bpy.data.curves.new("t" + label, "FONT")
    t.body = label
    t.size = 0.09
    t.align_x = "CENTER"
    to = bpy.data.objects.new("t" + label, t)
    bpy.context.scene.collection.objects.link(to)
    to.location = (ob.location.x, -0.4, -0.18)
    to.rotation_euler.x = math.radians(90)
body.hide_render = True

sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "SINGLE"
sc.display.shading.single_color = (0.78, 0.66, 0.56)
sc.display.shading.show_object_outline = True
sc.display.shading.show_cavity = True
sc.render.resolution_x, sc.render.resolution_y = (3800, 700) if len(FIGS) > 8 else (int(len(FIGS) * 300), 600)
cam = bpy.data.cameras.new("Cam")
co = bpy.data.objects.new("Cam", cam)
sc.collection.objects.link(co)
sc.camera = co
cam.type = "ORTHO"
cam.ortho_scale = len(FIGS) * step + 0.4
co.location = (0, -8, 0.85)
co.rotation_euler = (math.radians(90), 0, 0)
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
