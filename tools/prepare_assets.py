#!/usr/bin/env python3
"""Prepare the CC0 art assets used by the game.

Source packs (all CC0 1.0, by Quaternius - https://quaternius.com):
  * Universal Base Characters [Standard]
  * Modular Character Outfits - Fantasy [Standard]
  * Universal Animation Library 1 and 2 [Standard]
  * Stylized Nature MegaKit [Standard]
  * Fantasy Props MegaKit [Standard]

Usage:  python3 tools/prepare_assets.py <extracted-downloads-dir>
The directory must contain the unzipped packs (the layout of the official zips).

What it does:
  * copies the needed glTF/GLB files into assets/
  * downsizes textures (1024 px) so the repository stays small
  * bakes culture-specific recolours of the outfit textures (Earth Kingdom, Fire
    Nation, Water Tribes, Air Nomads, Kyoshi Island, Si Wong, outlaws)
"""
import colorsys
import glob
import os
import shutil
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets")
MAX_TEX = 1024


def find(src, pattern):
    hits = glob.glob(os.path.join(src, "**", pattern), recursive=True)
    if not hits:
        raise SystemExit("missing in downloads: " + pattern)
    return hits[0]


def copy_gltf(gltf_path, dest_dir, tex_size=MAX_TEX):
    """Copy a .gltf, its .bin and every referenced image (downsized)."""
    import json
    os.makedirs(dest_dir, exist_ok=True)
    src_dir = os.path.dirname(gltf_path)
    with open(gltf_path) as f:
        j = json.load(f)
    shutil.copy(gltf_path, dest_dir)
    for b in j.get("buffers", []):
        uri = b.get("uri")
        if uri:
            shutil.copy(os.path.join(src_dir, uri), dest_dir)
    for im in j.get("images", []):
        uri = im.get("uri")
        if not uri:
            continue
        dst = os.path.join(dest_dir, uri)
        if os.path.exists(dst):
            continue
        srcp = os.path.join(src_dir, uri)
        if not os.path.exists(srcp):
            # some packs keep textures one level up / in a Textures folder
            alt = glob.glob(os.path.join(glob.escape(os.path.dirname(src_dir)), "**", os.path.basename(uri).replace("_png.png", ".png")), recursive=True)
            if not alt:
                print("  warning: texture not found", uri)
                continue
            srcp = alt[0]
        save_downsized(srcp, dst, tex_size)


def save_downsized(src, dst, size):
    im = Image.open(src)
    if max(im.size) > size:
        im = im.resize((size, size), Image.LANCZOS)
    im.save(dst)


# ---------------------------------------------------------------------------
# Culture recolours
# ---------------------------------------------------------------------------
# Each recolour maps hue bands of the source texture to new colours while
# keeping the painted shading (luminance) of the original.
CULTURES = {
    # name: (primary cloth, secondary cloth/leather, light cloth)
    "earth":   ((0.30, 0.47, 0.22), (0.45, 0.33, 0.20), (0.78, 0.72, 0.52)),
    "fire":    ((0.62, 0.10, 0.08), (0.16, 0.10, 0.10), (0.85, 0.66, 0.30)),
    "water":   ((0.15, 0.32, 0.62), (0.55, 0.47, 0.38), (0.90, 0.92, 0.95)),
    "south":   ((0.20, 0.36, 0.60), (0.48, 0.38, 0.28), (0.88, 0.88, 0.86)),
    "air":     ((0.92, 0.52, 0.10), (0.85, 0.66, 0.20), (0.96, 0.84, 0.45)),
    "kyoshi":  ((0.16, 0.50, 0.30), (0.75, 0.58, 0.18), (0.92, 0.88, 0.70)),
    "sand":    ((0.72, 0.58, 0.38), (0.45, 0.22, 0.14), (0.88, 0.80, 0.62)),
    "outlaw":  ((0.33, 0.22, 0.30), (0.25, 0.20, 0.16), (0.60, 0.55, 0.48)),
    "swamp":   ((0.32, 0.38, 0.20), (0.35, 0.26, 0.16), (0.62, 0.60, 0.42)),
}


def recolour(src, dst, culture, kind):
    primary, secondary, light = [np.array(c) for c in CULTURES[culture]]
    im = np.asarray(Image.open(src).convert("RGB").resize((MAX_TEX, MAX_TEX), Image.LANCZOS)).astype(np.float32) / 255.0
    flat = im.reshape(-1, 3)
    hsv = np.array(list(map(lambda c: colorsys.rgb_to_hsv(*c), flat)))
    h, s, v = hsv[:, 0] * 360.0, hsv[:, 1], hsv[:, 2]
    lum = flat @ np.array([0.299, 0.587, 0.114])
    out = flat.copy()

    def apply(mask, colour, ref_lum):
        shade = np.clip(lum[mask] / ref_lum, 0.25, 1.6)[:, None]
        out[mask] = np.clip(colour[None, :] * shade, 0.0, 1.0)

    if kind == "ranger":
        green = (h > 60) & (h < 170) & (s > 0.2)
        leather = (h <= 60) & (s > 0.3) & (v < 0.75)
        apply(green, primary, 0.35)
        apply(leather, secondary, 0.38)
    else:  # peasant
        linen = (h < 70) & (s < 0.45) & (v > 0.55)
        cloth = (h < 70) & (v <= 0.55) & (v > 0.12) & (s > 0.25)
        apply(linen, light, 0.75)
        apply(cloth, primary, 0.30)
    img = Image.fromarray((out.reshape(im.shape) * 255).astype(np.uint8))
    img.save(dst, quality=90)


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    src = sys.argv[1]
    if os.path.exists(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT)

    # Characters ----------------------------------------------------------
    for name in ["Superhero_Male_FullBody.gltf", "Superhero_Female_FullBody.gltf"]:
        p = [x for x in glob.glob(os.path.join(src, "**", name), recursive=True) if "Godot" in x][0]
        copy_gltf(p, os.path.join(OUT, "characters", "base"))
        print("base", name)
    for light in ["T_Superhero_Male_Ligh.png", "T_Superhero_Female_Light_BaseColor.png"]:
        save_downsized(find(src, light), os.path.join(OUT, "characters", "base", light), MAX_TEX)
    hair_dir = [d for d in glob.glob(os.path.join(src, "**", "Rigged to Head Bone", "glTF*"), recursive=True)][0]
    for g in glob.glob(os.path.join(glob.escape(hair_dir), "*.gltf")):
        copy_gltf(g, os.path.join(OUT, "characters", "hair"))
    print("hair", len(glob.glob(os.path.join(glob.escape(hair_dir), "*.gltf"))))
    outfit_dir = [d for d in glob.glob(os.path.join(src, "**", "Outfits"), recursive=True) if "glTF" in d][0]
    for g in glob.glob(os.path.join(glob.escape(outfit_dir), "*.gltf")):
        copy_gltf(g, os.path.join(OUT, "characters", "outfits"))
    print("outfits", len(glob.glob(os.path.join(glob.escape(outfit_dir), "*.gltf"))))

    # Culture recolours
    rec_dir = os.path.join(OUT, "characters", "culture")
    os.makedirs(rec_dir)
    peasant = find(src, "T_Peasant_BaseColor.png")
    ranger = find(src, "T_Ranger_BaseColor.png")
    for c in CULTURES:
        recolour(peasant, os.path.join(rec_dir, "peasant_%s.jpg" % c), c, "peasant")
        recolour(ranger, os.path.join(rec_dir, "ranger_%s.jpg" % c), c, "ranger")
        print("recolour", c)

    # Animations -------------------------------------------------------------
    anim_dir = os.path.join(OUT, "animations")
    os.makedirs(anim_dir)
    shutil.copy(find(src, "UAL1_Standard.glb"), anim_dir)
    shutil.copy(find(src, "UAL2_Standard.glb"), anim_dir)

    # Nature -----------------------------------------------------------------
    nature_src = os.path.dirname(find(src, "CommonTree_1.gltf"))
    for g in glob.glob(os.path.join(glob.escape(nature_src), "*.gltf")):
        copy_gltf(g, os.path.join(OUT, "nature"), 512)
    print("nature", len(glob.glob(os.path.join(glob.escape(nature_src), "*.gltf"))))

    # Props --------------------------------------------------------------------
    props = ["Barrel", "Barrel_Apples", "Bench", "Bucket_Wooden_1", "Cauldron", "Chest_Wood", "Crate_Wooden",
             "FarmCrate_Apple", "FarmCrate_Carrot", "FarmCrate_Empty", "Lantern_Wall", "Pot_1", "Pot_1_Lid",
             "Rope_1", "Scroll_1", "Scroll_2", "Stall_Cart_Empty", "Stall_Empty", "Stool", "Table_Large",
             "Vase_2", "Vase_4", "WeaponStand", "Workbench", "Bag", "Pouch_Large", "Mug", "Dummy", "Anvil",
             "Torch_Metal", "Shelf_Simple", "Book_Stack_1", "Coin_Pile", "Chair_1", "Cage_Small"]
    props_src = os.path.dirname(find(src, "Stall_Empty.gltf"))
    for p in props:
        copy_gltf(os.path.join(props_src, p + ".gltf"), os.path.join(OUT, "props"), 1024)
    print("props", len(props))

    with open(os.path.join(OUT, "LICENSES.md"), "w") as f:
        f.write(LICENSE_TEXT)
    total = sum(os.path.getsize(os.path.join(d, x)) for d, _, fs in os.walk(OUT) for x in fs)
    print("assets size: %.1f MB" % (total / 1e6))


LICENSE_TEXT = """# Third-party art

All models, textures and animations in this folder were made by **Quaternius**
(https://quaternius.com, https://www.patreon.com/quaternius) and are released
under **CC0 1.0 Universal (public domain)**:
https://creativecommons.org/publicdomain/zero/1.0/

| Folder | Source pack |
|---|---|
| characters/base, characters/hair | Universal Base Characters (Standard) |
| characters/outfits | Modular Character Outfits - Fantasy (Standard) |
| characters/culture | recoloured from the outfit textures by tools/prepare_assets.py |
| animations | Universal Animation Library 1 and 2 (Standard) |
| nature | Stylized Nature MegaKit (Standard) |
| props | Fantasy Props MegaKit (Standard) |

Textures were downsized for repository size. CC0 requires no attribution, but
the artist deserves it: thank you, Quaternius.
"""

if __name__ == "__main__":
    main()
