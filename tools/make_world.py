#!/usr/bin/env python3
"""Generate the world map's terrain: land, height, biome, forest and rivers.

The coastlines are drawn by hand as outlines (polygons, ellipses and capsules)
and then broken up the way real coasts are: the coordinates are warped by
low-frequency noise (bays and headlands) and the edge is roughened by fractal
noise (coves and points). Mountain ranges follow hand-placed ridge lines;
rivers follow hand-placed courses with noise meanders. Every settlement in
scripts/autoload/game_data.gd is guaranteed dry land around it.

Writes, at 2 map units per sample (801 x 601):
  assets/world/height.bin  float32 heights (sea floor negative)
  assets/world/info.bin    RGBA8: biome id, coast distance (128 = coast,
                           +4 per unit inland), forest density, river

Usage: python3 tools/make_world.py [preview.png]
"""
import math
import os
import re
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAP_W, MAP_H = 1600, 1200
STEP = 2.0
W, H = int(MAP_W / STEP) + 1, int(MAP_H / STEP) + 1
BIOMES = ["ocean", "grass", "forest", "mountain", "snow", "desert", "swamp", "volcanic", "highland", "beach"]

ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)
X = xs * STEP
Y = ys * STEP


# --- noise ------------------------------------------------------------------
def value_noise(cells, seed):
    """Smooth noise in [-1, 1] with about `cells` features across the map width."""
    rng = np.random.default_rng(seed)
    gw = max(2, int(cells))
    gh = max(2, int(cells * MAP_H / MAP_W))
    g = rng.random((gh + 3, gw + 3)).astype(np.float32)
    img = Image.fromarray(g, "F").resize((int((gw + 3) * W / gw), int((gh + 3) * H / gh)), Image.BICUBIC)
    a = np.asarray(img)[:H, :W]
    return (a - 0.5) * 2.0


def fbm(cells, octaves, seed, gain=0.5):
    out = np.zeros((H, W), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        out += value_noise(cells * (2 ** o), seed + o * 101) * amp
        tot += amp
        amp *= gain
    return out / tot


def blur(a, r):
    """Approximate gaussian blur: three separable box blurs of radius r samples."""
    out = a.astype(np.float32)
    for _ in range(3):
        for axis in (0, 1):
            p = np.pad(out, [((r + 1, r) if ax == axis else (0, 0)) for ax in (0, 1)], mode="edge")
            c = np.cumsum(p, axis=axis)
            if axis == 0:
                out = (c[2 * r + 1:] - c[:-2 * r - 1]) / (2 * r + 1)
            else:
                out = (c[:, 2 * r + 1:] - c[:, :-2 * r - 1]) / (2 * r + 1)
    return out


# --- shapes (signed distance in map units, positive inside) -----------------
def sd_polygon(px, py, pts):
    pts = np.asarray(pts, np.float32)
    d = np.full(px.shape, 1e9, np.float32)
    inside = np.zeros(px.shape, bool)
    n = len(pts)
    for i in range(n):
        ax, ay = pts[i]
        bx, by = pts[(i + 1) % n]
        ex, ey = bx - ax, by - ay
        wx, wy = px - ax, py - ay
        t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
        dx, dy = wx - ex * t, wy - ey * t
        d = np.minimum(d, np.sqrt(dx * dx + dy * dy))
        cond = ((ay <= py) & (py < by)) | ((by <= py) & (py < ay))
        xint = ax + (py - ay) * ex / np.where(ey == 0, 1e-6, ey)
        inside ^= cond & (px < xint)
    return np.where(inside, d, -d)


def sd_ellipse(px, py, cx, cy, rx, ry, ang=0.0):
    a = math.radians(ang)
    dx, dy = px - cx, py - cy
    u = dx * math.cos(a) + dy * math.sin(a)
    v = -dx * math.sin(a) + dy * math.cos(a)
    r = np.sqrt((u / rx) ** 2 + (v / ry) ** 2)
    return (1.0 - r) * min(rx, ry)


def sd_capsule(px, py, a, b, r):
    ax, ay = a
    bx, by = b
    ex, ey = bx - ax, by - ay
    wx, wy = px - ax, py - ay
    t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
    return r - np.sqrt((wx - ex * t) ** 2 + (wy - ey * t) ** 2)


def dist_polyline(px, py, pts):
    d = np.full(px.shape, 1e9, np.float32)
    for i in range(len(pts) - 1):
        d = np.minimum(d, -sd_capsule(px, py, pts[i], pts[i + 1], 0.0))
    return d


# --- the world ----------------------------------------------------------------
EARTH = [(760, 300), (800, 240), (860, 215), (880, 165), (930, 140), (990, 160), (1040, 182), (1080, 162),
         (1150, 176), (1200, 158), (1260, 150), (1330, 166), (1390, 148), (1450, 174), (1500, 200),
         (1530, 262), (1508, 322), (1552, 372), (1538, 432), (1498, 462), (1530, 522), (1562, 582),
         (1540, 650), (1566, 716), (1548, 790), (1512, 838), (1478, 812), (1462, 760), (1420, 742), (1380, 794), (1330, 836),
         (1270, 812), (1236, 772), (1196, 748), (1150, 752), (1120, 790), (1090, 818), (1040, 834), (990, 842),
         (940, 800), (900, 762), (860, 762), (830, 822), (800, 882), (760, 922), (733, 902), (745, 850),
         (790, 780), (820, 730), (780, 700), (740, 652), (760, 600), (718, 560), (740, 500), (700, 450),
         (730, 390)]
FIRE_MAIN = [(285, 378), (322, 384), (352, 420), (357, 470), (346, 520), (372, 560), (422, 580), (452, 612),
             (432, 662), (392, 677), (340, 652), (290, 642), (243, 637), (223, 600), (240, 560), (250, 500),
             (258, 450), (265, 410)]
NORTH_WEST_ICE = [(140, -30), (705, -30), (692, 40), (662, 80), (692, 120), (642, 142), (590, 126), (560, 152),
                  (500, 142), (450, 157), (400, 152), (360, 122), (320, 97), (270, 107), (220, 92), (180, 72), (150, 40)]
NORTH_EAST_ICE = [(920, -30), (1392, -30), (1382, 30), (1352, 70), (1362, 112), (1320, 122), (1270, 97),
                  (1220, 102), (1170, 92), (1120, 107), (1060, 97), (1010, 82), (960, 62), (930, 30)]
SOUTH_WEST_ICE = [(180, 1230), (1012, 1230), (1002, 1142), (962, 1102), (902, 1082), (860, 1066), (800, 1076),
                  (740, 1062), (680, 1077), (620, 1087), (560, 1102), (500, 1122), (430, 1107), (380, 1112),
                  (320, 1097), (260, 1102), (210, 1132), (185, 1170)]
SOUTH_EAST_ICE = [(1130, 1230), (1422, 1230), (1412, 1160), (1382, 1122), (1332, 1112), (1272, 1102),
                  (1222, 1112), (1172, 1132), (1142, 1162)]

# ellipses: cx, cy, rx, ry, angle
ISLANDS = [
    (200, 470, 24, 20, 0),       # Crescent Island
    (458, 508, 34, 24, 15),      # Ember Island
    (328, 290, 58, 33, -5),      # Kurozan
    (116, 570, 38, 56, 8),       # Kagari
    (105, 722, 50, 46, 0),       # the Sun Warriors' isle
    (262, 768, 58, 30, -10),     # Tsurugi
    (356, 810, 24, 17, 20),      # Akashima
    (430, 705, 21, 15, 0),       # Umibe
    (520, 330, 82, 56, -15),     # Western Air Temple
    (600, 982, 62, 46, 10),      # Patola peaks
    (936, 1036, 38, 20, -20),    # Whaletail
    (772, 54, 40, 24, 0),        # Tuktu's ice island
    (1120, 960, 30, 22, 0),      # Pearl Isles: Tidehall
    (1184, 1002, 24, 18, 30),    # Shellbay
    (1058, 994, 22, 16, -20),    # Kelp Rock
    (470, 900, 15, 12, 0),       # Gull Rock
    (668, 762, 18, 13, 25),      # Oyster Isle
    (180, 900, 20, 15, -10),     # Tern Isle
    (1556, 862, 17, 13, 0),      # Driftwood Key
    (1520, 1010, 20, 15, 15),    # Kelp Isle
    (1050, 900, 9, 7, 0), (1250, 930, 8, 6, 0), (820, 990, 10, 7, 0), (1450, 900, 9, 7, 0),  # skerries
    (60, 380, 12, 9, 0), (90, 850, 9, 7, 0), (1580, 300, 10, 8, 0),
]
# the Strait Isles: two long islands with a channel between them
CAPSULES = [((560, 444), (567, 530), 17), ((555, 588), (571, 666), 16)]
LAKES = [(305, 446, 8), (1062, 398, 11), (1385, 352, 13), (1180, 255, 9)]

# ridges: points, peak height, half-width
RIDGES = [
    ([(760, 360), (800, 400), (845, 470), (852, 540), (880, 610)], 14, 26),      # the Kolau range by Omashu
    ([(985, 205), (1060, 262), (1150, 250), (1250, 252), (1330, 238), (1405, 285)], 16, 28),  # the northern range
    ([(1492, 280), (1480, 380), (1503, 480), (1490, 560), (1522, 640)], 14, 22),   # the eastern range
    ([(1180, 440), (1232, 482), (1280, 525)], 9, 18),                               # the Serpent's spine
    ([(935, 600), (1000, 560)], 6, 18),                                              # southern hills
    ([(250, 470), (300, 470), (310, 410)], 13, 22),                                  # Fire main island volcanoes
    ([(600, 980), (610, 965)], 17, 26),                                              # Patola
    ([(320, 285), (340, 280)], 12, 16),                                              # Kurozan's peak
    ([(450, 500), (452, 502)], 9, 10),                                               # Ember Island's volcano
    ([(110, 560), (118, 590)], 7, 18),                                               # Kagari
    ([(500, 320), (560, 330)], 8, 30),                                               # the Western Air Temple's cliffs
]

RIVERS = [
    [(1252, 252), (1262, 330), (1243, 440), (1296, 520), (1302, 620), (1262, 700), (1290, 770), (1302, 840)],
    [(830, 500), (792, 560), (760, 612), (722, 640)],
    [(985, 560), (968, 655), (942, 722), (930, 800)],
    [(1482, 470), (1520, 498), (1560, 500)],
    [(1078, 262), (1094, 225), (1090, 190), (1084, 150)],
    [(1150, 440), (1130, 520), (1078, 562)],
]

REGIONS = [  # cx, cy, rx, ry, biome (with ragged edges)
    (1140, 592, 138, 86, "desert"),
    (965, 655, 58, 42, "swamp"),
    (1305, 785, 66, 40, "swamp"),
    (330, 520, 175, 175, "volcanic"),
    (328, 290, 62, 38, "volcanic"),
    (105, 722, 58, 52, "forest"),
    (520, 330, 86, 60, "highland"),
]


def settlements():
    src = open(os.path.join(ROOT, "scripts", "autoload", "game_data.gd")).read()
    start = src.index("var settlements := {")
    out = []
    for m in re.finditer(r'"pos": Vector2\(([\d.]+), ([\d.]+)\)', src[start:]):
        out.append((float(m.group(1)), float(m.group(2))))
    return out


def main():
    # warped coordinates: bays and headlands, then fine roughness
    wx = fbm(7, 3, 11) * 34.0 + fbm(22, 2, 13) * 12.0 + fbm(60, 2, 12) * 5.0
    wy = fbm(7, 3, 21) * 34.0 + fbm(22, 2, 23) * 12.0 + fbm(60, 2, 22) * 5.0
    px, py = X + wx, Y + wy
    sd = sd_polygon(px, py, EARTH)
    for poly in (FIRE_MAIN, NORTH_WEST_ICE, NORTH_EAST_ICE, SOUTH_WEST_ICE, SOUTH_EAST_ICE):
        sd = np.maximum(sd, sd_polygon(px, py, poly))
    for e in ISLANDS:
        sd = np.maximum(sd, sd_ellipse(px, py, *e))
    for a, b, r in CAPSULES:
        sd = np.maximum(sd, sd_capsule(px, py, a, b, r))
    sd += fbm(60, 4, 31) * 5.0
    for cx, cy, r in LAKES:
        sd = np.minimum(sd, np.sqrt((X - cx) ** 2 + (Y - cy) ** 2) - r + fbm(80, 2, 41) * 2.0)
    # dry land under every settlement
    for (sx, sy) in settlements():
        d = np.sqrt((X - sx) ** 2 + (Y - sy) ** 2)
        sd = np.maximum(sd, 7.0 - d * 0.6)
    land = sd > 0

    # height
    # the sea floor follows a smoothed coast, so depth has no blotches
    sd_soft = blur(sd, 6)
    sea = -0.5 - np.clip(-np.minimum(sd_soft, sd), 0, 70) / 70.0 * 6.0
    h = np.where(land, 0.6 + np.clip(sd, 0, 50) / 50.0 * 3.0, sea)
    hills = fbm(24, 4, 51) * 0.5 + 0.5
    h += np.where(land, hills * 2.5 * np.clip(sd / 12.0, 0, 1), 0)
    ridged = 1.0 - np.abs(fbm(30, 4, 61))
    for pts, peak, width in RIDGES:
        d = dist_polyline(X + wx * 0.5, Y + wy * 0.5, pts)
        h += np.where(land, peak * np.exp(-(d / width) ** 2) * (0.45 + 0.75 * ridged ** 2) * np.clip(sd / 8.0, 0, 1), 0)
    # Caldera: a ring crater around the capital
    d = np.sqrt((X - 318) ** 2 + (Y - 560) ** 2)
    h += 8.0 * np.exp(-((d - 20) / 7.0) ** 2)
    # rivers
    river = np.zeros((H, W), np.float32)
    for course in RIVERS:
        rd = dist_polyline(X + fbm(50, 2, 71) * 9.0, Y + fbm(50, 2, 72) * 9.0, course)
        river = np.maximum(river, np.clip(1.0 - rd / 3.2, 0, 1))
    h = np.where(land, np.maximum(0.3, h - river * 1.2), h)
    # settlements stand on level ground
    for (sx, sy) in settlements():
        d = np.sqrt((X - sx) ** 2 + (Y - sy) ** 2)
        k = np.clip(1.0 - (d - 5.0) / 12.0, 0, 1) ** 2
        ring = land & (d > 14) & (d < 26)
        base = float(np.median(h[ring])) if ring.any() else 0.8
        base = max(0.6, min(base, 7.0))
        h = np.where(land, h * (1 - k) + base * k, h)

    # biomes
    biome = np.full((H, W), BIOMES.index("grass"), np.uint8)
    rough = fbm(50, 3, 81) * 0.18
    for cx, cy, rx, ry, b in REGIONS:
        r = np.sqrt(((X - cx) / rx) ** 2 + ((Y - cy) / ry) ** 2) + rough
        biome[r < 1.0] = BIOMES.index(b)
    forest = np.clip((fbm(18, 4, 91) * 0.5 + 0.5 - 0.52) * 4.0 + river * 0.4, 0, 1)
    is_grass = biome == BIOMES.index("grass")
    biome[is_grass & (forest > 0.35)] = BIOMES.index("forest")
    biome[(h > 9.5) & (biome != BIOMES.index("desert"))] = BIOMES.index("mountain")
    polar = (Y + wy * 2 < 172) | (Y + wy * 2 > 1035)
    biome[polar] = BIOMES.index("snow")
    biome[land & (sd < 1.6) & ~polar & (biome != BIOMES.index("swamp"))] = BIOMES.index("beach")
    biome[~land] = BIOMES.index("ocean")
    forest = np.where(np.isin(biome, [BIOMES.index("forest"), BIOMES.index("swamp")]), np.maximum(forest, 0.4), forest * 0.25)
    forest[~land] = 0

    coast = np.clip(128 + sd * 4.0, 0, 255).astype(np.uint8)
    info = np.stack([biome, coast, (forest * 255).astype(np.uint8), (river * 255).astype(np.uint8)], axis=-1)
    out = os.path.join(ROOT, "assets", "world")
    os.makedirs(out, exist_ok=True)
    h.astype("<f4").tofile(os.path.join(out, "height.bin"))
    info.astype(np.uint8).tofile(os.path.join(out, "info.bin"))
    print("land %.1f%%, height %.1f..%.1f" % (land.mean() * 100, h.min(), h.max()))
    if len(sys.argv) > 1:
        col = np.array([[40, 80, 130], [110, 150, 80], [60, 110, 60], [130, 120, 105], [235, 240, 245],
                        [220, 195, 135], [80, 100, 70], [100, 80, 70], [130, 140, 100], [215, 205, 160]], np.uint8)
        img = col[biome].astype(np.float32)
        shade = np.clip(1.0 + np.gradient(h, axis=1) * 0.25 - np.gradient(h, axis=0) * 0.25, 0.6, 1.3)
        img = img * shade[..., None]
        img[river > 0.3] = [60, 110, 170]
        for (sx, sy) in settlements():
            img[int(sy / STEP) - 1:int(sy / STEP) + 2, int(sx / STEP) - 1:int(sx / STEP) + 2] = [220, 30, 30]
        Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save(sys.argv[1])


if __name__ == "__main__":
    main()
