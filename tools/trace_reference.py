#!/usr/bin/env python3
"""Trace the world's geography from a reference map image.

The reference (a painted map of the series' world, kept outside the
repository) is read for its geography only: which ground is land, sea, river
or lake, what kind of country each place is (desert, forest, grassland,
mountain, ice, volcanic ground) and where the mountains stand. Painted labels
and decorations are removed: thin strokes and small specks are filtered out,
and holes the labels leave in the land are filled.

Writes assets/world/geography.png at the game's terrain grid (801 x 601, two
map units per sample):
  R  land (255) or water (0)
  G  biome index (see make_world.BIOMES)
  B  mountain density 0..255
  A  river 0..255

Usage: python3 tools/trace_reference.py <reference image> [preview.png]
"""
import os
import sys
from collections import deque

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 801, 601
BIOMES = ["ocean", "grass", "forest", "mountain", "snow", "desert", "swamp", "volcanic", "highland", "beach"]


def shift(a, dy, dx):
    out = np.zeros_like(a)
    ys = slice(max(dy, 0), a.shape[0] + min(dy, 0))
    yd = slice(max(-dy, 0), a.shape[0] + min(-dy, 0))
    xs = slice(max(dx, 0), a.shape[1] + min(dx, 0))
    xd = slice(max(-dx, 0), a.shape[1] + min(-dx, 0))
    out[ys, xs] = a[yd, xd]
    return out


def erode(a, r=1):
    out = a.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dy * dy + dx * dx <= r * r:
                out &= shift(a, dy, dx)
    return out


def dilate(a, r=1):
    out = a.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dy * dy + dx * dx <= r * r:
                out |= shift(a, dy, dx)
    return out


def components(mask):
    """Label 4-connected components: returns (labels, sizes, touches_border)."""
    lab = np.zeros(mask.shape, np.int32)
    sizes = [0]
    border = [False]
    hh, ww = mask.shape
    n = 0
    for y0 in range(hh):
        row = mask[y0]
        for x0 in np.nonzero(row & (lab[y0] == 0))[0]:
            if lab[y0, x0]:
                continue
            n += 1
            lab[y0, x0] = n
            q = deque([(y0, x0)])
            size = 0
            touch = False
            while q:
                y, x = q.popleft()
                size += 1
                if y == 0 or x == 0 or y == hh - 1 or x == ww - 1:
                    touch = True
                for yy, xx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                    if 0 <= yy < hh and 0 <= xx < ww and mask[yy, xx] and not lab[yy, xx]:
                        lab[yy, xx] = n
                        q.append((yy, xx))
            sizes.append(size)
            border.append(touch)
    return lab, np.array(sizes), np.array(border)


## Painted labels on land, as boxes in the coordinates of the reference
## scaled to 2000 x 1500 (x0, y0, x1, y1).
LAND_LABELS = [
    (892, 52, 1212, 96), (950, 92, 1010, 120), (1015, 140, 1110, 160), (1170, 150, 1225, 162),
    (835, 265, 895, 298), (620, 312, 705, 338), (425, 368, 610, 388), (570, 408, 705, 430),
    (765, 388, 815, 402), (860, 388, 910, 418), (970, 330, 1080, 390), (1095, 330, 1125, 410),
    (1175, 195, 1265, 222), (1175, 248, 1310, 270), (1250, 305, 1340, 338), (1755, 276, 1855, 290),
    (935, 425, 980, 440), (1048, 428, 1100, 442), (1100, 442, 1150, 455), (962, 458, 1012, 470),
    (1070, 472, 1105, 488), (1325, 415, 1445, 430), (1555, 432, 1668, 476), (1625, 452, 1675, 480),
    (790, 535, 840, 550), (712, 563, 765, 590), (962, 530, 1040, 555), (1010, 566, 1060, 592),
    (1105, 520, 1210, 570), (1355, 520, 1410, 535), (1185, 625, 1235, 650), (1280, 628, 1520, 660),
    (1100, 683, 1145, 695), (1185, 640, 1275, 690), (1340, 665, 1430, 740), (1470, 672, 1525, 695),
    (1140, 710, 1205, 760), (1420, 745, 1475, 770), (1530, 738, 1600, 780), (1180, 770, 1260, 795),
    (1325, 785, 1415, 810), (1215, 812, 1270, 825), (1405, 780, 1480, 860), (1510, 852, 1540, 865),
    (1195, 890, 1295, 920), (1325, 932, 1380, 945), (1170, 953, 1205, 965), (1420, 920, 1450, 1015),
    (365, 705, 445, 735), (365, 760, 545, 790), (262, 738, 310, 765), (505, 715, 565, 740),
    (550, 752, 595, 778), (325, 635, 400, 650), (618, 682, 660, 697), (695, 688, 760, 713),
    (705, 752, 760, 783), (410, 835, 460, 860), (555, 887, 605, 900), (990, 940, 1110, 952),
    (825, 1058, 905, 1083), (830, 1115, 965, 1137), (930, 1060, 1050, 1135), (1410, 1072, 1540, 1090),
    (1695, 945, 1745, 972), (1785, 925, 1860, 940), (1820, 833, 1905, 860), (1830, 805, 1980, 828),
    (1780, 772, 1880, 798), (1730, 615, 1785, 640), (860, 1238, 945, 1280), (1055, 1262, 1115, 1290),
    (825, 1312, 920, 1340), (870, 1335, 1195, 1382),
]


def blur(a, r):
    """Box blur of radius r, three passes (close to a gaussian)."""
    out = a.astype(np.float32)
    for _ in range(3):
        for axis in (0, 1):
            p = np.pad(out, [((r + 1, r) if ax == axis else (0, 0)) for ax in (0, 1)], mode="edge")
            c = np.cumsum(p, axis=axis)
            out = (c[2 * r + 1:] - c[:-2 * r - 1]) / (2 * r + 1) if axis == 0 else (c[:, 2 * r + 1:] - c[:, :-2 * r - 1]) / (2 * r + 1)
    return out


def fill_from_around(a, mask, r=6):
    """Replace values under mask with a blur of the unmasked values around."""
    known = (~mask).astype(np.float32)
    num = blur(a * known, r)
    den = blur(known, r)
    out = a.copy()
    out[mask] = (num / np.maximum(den, 1e-4))[mask]
    return out


def box(a):
    """Resample an image-resolution array to the terrain grid by averaging."""
    return np.array(Image.fromarray(a.astype(np.float32), "F").resize((W, H), Image.BOX))


def main():
    src = np.asarray(Image.open(sys.argv[1]).convert("RGB")).astype(np.int32)
    r, g, b = src[..., 0], src[..., 1], src[..., 2]
    mx = src.max(axis=2)
    mn = src.min(axis=2)
    sea_px = (b - r >= 14) & (g - r >= 12) & (np.abs(g - b) < 30)
    white_px = (mn > 165) & ((mx - mn) < 30)
    # coloured land, then white land: big white areas (ice shelves, snowfields)
    # are land, small white specks are the fill of painted letters
    land = box(~sea_px & ~white_px) > 0.5
    white = box(white_px) > 0.5
    lab, sizes, border = components(white)
    big = sizes >= 60
    big[0] = False
    land = land | big[lab]
    # labels: thin strokes go
    land = dilate(erode(land, 1), 1)
    # small specks and the dark frame at the image's edges go
    lab, sizes, border = components(land)
    keep = (sizes >= 10) & ~border
    keep[0] = False
    land = keep[lab]
    # words painted on the sea are thin: a land component that vanishes when
    # eroded is lettering, not an island
    lab, sizes, border = components(land)
    core = erode(land, 2)
    has_core = np.zeros(sizes.size, bool)
    has_core[np.unique(lab[core])] = True
    keep = has_core | (sizes > 900)
    keep[0] = False
    land = keep[lab]
    # holes in the land left by labels are filled; lakes (bigger) stay
    water = ~land
    lab, sizes, border = components(water)
    small = (sizes < 45) & ~border
    small[0] = False
    land |= small[lab]
    # rivers: water channels that a light closing of the land would bridge
    closed = erode(dilate(land, 2), 2)
    river = closed & ~land
    lab, sizes, border = components(river)
    river = river & (sizes[lab] >= 12)
    land = land | river

    # biomes, by the colour that covers most of each sample
    sat = mx - mn
    classes = {
        "snow": (mn > 170) & (sat < 30),
        "desert": (r > 175) & (g > 140) & (b < 150) & (r - b > 55),
        "forest": ((g < 105) & (r < 110) & (b < 70)) | ((r > 115) & (r - g > 35) & (b < 70)),
        "grass": (g > 115) & (g >= r) & (b < 115) & (g - b > 35),
        "mountain": (r > 95) & (r < 180) & (b > 70) & (r - b < 60) & (r >= g) & (sat < 70),
    }
    frac = {k: box(v) for k, v in classes.items()}
    # painted labels on land: their letters are not snow or mountains
    labels = np.zeros((H, W), bool)
    for x0, y0, x1, y1 in LAND_LABELS:
        f = 1600.0 / 2000.0 / 2.0                       # 2000-wide reference coords to grid
        labels[int(y0 * f) - 2:int(y1 * f) + 3, int(x0 * f) - 2:int(x1 * f) + 3] = True
    for k in frac:
        frac[k] = fill_from_around(frac[k], labels)
    names = list(frac.keys())
    stack = np.stack([frac[k] for k in names])
    best = np.array(names)[stack.argmax(axis=0)]
    biome = np.full((H, W), BIOMES.index("grass"), np.uint8)
    for k in names:
        biome[best == k] = BIOMES.index(k)
    ys, xs = np.mgrid[0:H, 0:W]
    mx_x, my_y = xs * 2.0, ys * 2.0                        # map units
    polar = (my_y < 175) | (my_y > 930)
    snowy = biome == BIOMES.index("snow")
    biome[snowy & ~polar] = BIOMES.index("mountain")      # snow caps away from the poles
    biome[polar & land & ~np.isin(biome, [BIOMES.index("forest"), BIOMES.index("grass")])] = BIOMES.index("snow")
    # the Fire Islands' dark ground is volcanic; the great swamp is swamp
    fire = (mx_x < 560) & (my_y > 420) & (my_y < 740)
    biome[fire & np.isin(biome, [BIOMES.index("mountain")])] = BIOMES.index("volcanic")
    swamp = ((mx_x - 972) / 50) ** 2 + ((my_y - 700) / 30) ** 2 < 1.0
    biome[swamp & land] = BIOMES.index("swamp")
    biome[~land] = BIOMES.index("ocean")
    mountain = fill_from_around(box((classes["mountain"] | (classes["snow"])).astype(np.float32)), labels)
    mountain[polar] *= 0.4
    mountain[~land] = 0

    out = np.stack([land.astype(np.uint8) * 255, biome, np.clip(mountain * 255, 0, 255).astype(np.uint8),
                    river.astype(np.uint8) * 255], axis=-1)
    path = os.path.join(ROOT, "assets", "world", "geography.png")
    Image.fromarray(out, "RGBA").save(path)
    print("wrote", path, "land %.1f%%" % (land.mean() * 100))
    if len(sys.argv) > 2:
        col = np.array([[60, 90, 110], [120, 150, 80], [50, 80, 40], [140, 125, 110], [235, 238, 240],
                        [215, 185, 120], [80, 90, 50], [90, 70, 60], [130, 140, 100], [215, 205, 160]], np.uint8)
        img = col[biome].astype(np.float32)
        img *= (0.75 + 0.5 * mountain)[..., None]
        img[river] = [70, 120, 170]
        Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save(sys.argv[2])


if __name__ == "__main__":
    main()
