#!/usr/bin/env python3
"""Draw the flame flipbooks in the hand-inked style of the animated series.

Fire there is flat colour, hard-edged: a deep red outer tongue, orange and
yellow inside it, a pale core, curling tips, and a dark brush outline. This
script draws exactly that, procedurally, one frame at a time at 4x and
downsamples with nearest-neighbour so the edges stay hard (no blur, no
glow). The frames loop: tongues sway and curl through one cycle.

Writes assets/fx/:
  flame.png / flame_blue.png        8 frames, upright tongues (ground fire,
                                    people burning, walls of fire)
  fireball.png / fireball_blue.png  8 frames, a round head with a curling
                                    tail pointing along -X (projectiles)
  smoke.png                         6 frames, inked puffs that rise and spread

Usage: python3 tools/paint_flames.py
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "fx")
FS = 128          # frame size
SS = 4            # supersample
FRAMES = 8
INK = (30, 10, 8, 255)

RED = {"outer": (178, 28, 20), "mid": (238, 108, 22), "yellow": (255, 206, 56), "core": (255, 246, 196), "streak": (120, 14, 12)}
BLUE = {"outer": (28, 70, 170), "mid": (60, 140, 235), "yellow": (140, 214, 255), "core": (236, 250, 255), "streak": (16, 40, 110)}


def tongue(cx, cy, ang, length, width, sway, phase, curl):
    """Polygon of one flame tongue from base (cx, cy) heading `ang` (radians,
    0 = up), swaying and curling at the tip. Returns (polygon, spine)."""
    n = 28
    spine = []
    for i in range(n + 1):
        t = i / n
        off = sway * math.sin(phase + t * 3.2) * t * length * 0.35 + curl * (t ** 3) * length * 0.5
        # along the heading plus a sideways offset
        dx = math.sin(ang) * t * length + math.cos(ang) * off
        dy = -math.cos(ang) * t * length + math.sin(ang) * off
        spine.append((cx + dx, cy + dy))
    left, right = [], []
    for i, (x, y) in enumerate(spine):
        t = i / n
        x0, y0 = spine[max(0, i - 1)]
        x1, y1 = spine[min(n, i + 1)]
        tx, ty = x1 - x0, y1 - y0
        ln = math.hypot(tx, ty) or 1.0
        nx, ny = -ty / ln, tx / ln
        w = width * (1 - t) ** 0.8 * min(1.0, 0.25 + t * 7.0)
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return left + right[::-1], spine


def scaled(poly_fn, **kw):
    return poly_fn(**kw)


def draw_cluster(d_out, d_fill, tongues, pal):
    """tongues: list of dicts of tongue() args. Layers are filled for all
    tongues together so the colour bands merge like the hand-drawn ones."""
    polys = []
    for tg in tongues:
        poly, spine = tongue(**tg)
        polys.append((poly, spine, tg))
    return polys


def render_flame(f, pal):
    s = FS * SS
    phase = 2 * math.pi * f / FRAMES
    base_y = s * 0.94
    cx = s * 0.5
    wob = 1.0 + 0.07 * math.sin(phase * 2)
    tongues = [
        dict(cx=cx, cy=base_y, ang=0.0, length=s * 0.84 * wob, width=s * 0.17, sway=0.8, phase=phase, curl=0.3 * math.sin(phase + 1.0) + 0.3),
        dict(cx=cx - s * 0.12, cy=base_y, ang=-0.2, length=s * 0.58 * (1.0 + 0.1 * math.sin(phase * 2 + 2)), width=s * 0.11, sway=0.9, phase=phase + 2.1, curl=-0.35 - 0.15 * math.sin(phase + 2)),
        dict(cx=cx + s * 0.12, cy=base_y, ang=0.22, length=s * 0.5 * (1.0 + 0.1 * math.sin(phase * 2 + 4)), width=s * 0.1, sway=0.9, phase=phase + 4.0, curl=0.35 + 0.15 * math.sin(phase + 4)),
        dict(cx=cx + s * 0.04, cy=base_y, ang=0.12, length=s * 0.32, width=s * 0.07, sway=1.5, phase=phase + 5.5, curl=0.7),
    ]
    return paint(tongues, pal, s, ball=None)


def render_ball(f, pal):
    s = FS * SS
    phase = 2 * math.pi * f / FRAMES
    hx, hy = s * 0.7, s * 0.5
    r = s * 0.2 * (1.0 + 0.05 * math.sin(phase * 2))
    # tongues stream to the left (heading angle -90 deg), curling
    tongues = [
        dict(cx=hx, cy=hy, ang=-math.pi / 2, length=s * 0.66, width=r * 0.95, sway=1.0, phase=phase, curl=0.5 * math.sin(phase) + 0.3),
        dict(cx=hx, cy=hy - r * 0.4, ang=-math.pi / 2 - 0.35, length=s * 0.5, width=r * 0.6, sway=1.2, phase=phase + 2.2, curl=-0.5),
        dict(cx=hx, cy=hy + r * 0.4, ang=-math.pi / 2 + 0.35, length=s * 0.46, width=r * 0.55, sway=1.2, phase=phase + 4.1, curl=0.5),
    ]
    return paint(tongues, pal, s, ball=(hx, hy, r))


def paint(tongues, pal, s, ball):
    polys = [tongue(**tg) for tg in tongues]
    mask = Image.new("L", (s, s), 0)
    md = ImageDraw.Draw(mask)
    for poly, _spine in polys:
        md.polygon(poly, fill=255)
    if ball:
        bx, by, br = ball
        md.ellipse([bx - br, by - br, bx + br, by + br], fill=255)
    # dark brush outline around the whole silhouette
    outline = mask.filter(ImageFilter.MaxFilter(2 * (3 * SS // 2) + 1))
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    img.paste(Image.new("RGBA", (s, s), INK), mask=outline)
    d = ImageDraw.Draw(img)
    d.bitmap((0, 0), mask, fill=pal["outer"] + (255,))
    # inner layers: each a narrower, shorter copy of the tongue
    for key, wk, lk in (("mid", 0.68, 0.84), ("yellow", 0.42, 0.64), ("core", 0.2, 0.42)):
        for tg in tongues:
            t2 = dict(tg)
            t2["width"] = tg["width"] * wk
            t2["length"] = tg["length"] * lk
            poly, _ = tongue(**t2)
            d.polygon(poly, fill=pal[key] + (255,))
        if ball:
            bx, by, br = ball
            rr = br * {"mid": 0.82, "yellow": 0.58, "core": 0.32}[key]
            d.ellipse([bx - rr, by - rr, bx + rr, by + rr], fill=pal[key] + (255,))
    # a few dark brush streaks along the outer tongues
    for poly, spine in polys:
        pts = spine[3:int(len(spine) * 0.8)]
        pts = [(x + 0.0, y) for x, y in pts]
        if len(pts) > 2:
            d.line(pts, fill=pal["streak"] + (255,), width=SS)
    out = img.resize((FS, FS), Image.NEAREST)
    # hard alpha: no soft edges
    a = np.array(out)
    a[..., 3] = np.where(a[..., 3] > 127, 255, 0)
    return Image.fromarray(a)


def render_smoke(f):
    s = FS * SS
    frames = 6
    t = f / (frames - 1)
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    mask = Image.new("L", (s, s), 0)
    md = ImageDraw.Draw(mask)
    puffs = [(0.5, 0.78, 0.17), (0.4, 0.66, 0.13), (0.58, 0.62, 0.12)]
    cells = []
    for i, (px, py, pr) in enumerate(puffs):
        y = py - t * (0.18 + 0.05 * i)
        r = pr * (0.8 + 0.7 * t)
        x = px + math.sin(t * 3 + i) * 0.03
        cells.append((x * s, y * s, r * s))
        md.ellipse([(x - r) * s, (y - r) * s, (x + r) * s, (y + r) * s], fill=255)
    outline = mask.filter(ImageFilter.MaxFilter(2 * (2 * SS // 2) + 1))
    img.paste(Image.new("RGBA", (s, s), (40, 34, 32, 255)), mask=outline)
    d = ImageDraw.Draw(img)
    d.bitmap((0, 0), mask, fill=(108, 100, 96, 255))
    for x, y, r in cells:
        d.ellipse([x - r * 0.55, y - r * 0.6, x + r * 0.35, y + r * 0.3], fill=(150, 142, 136, 255))
    out = img.resize((FS, FS), Image.NEAREST)
    a = np.array(out)
    a[..., 3] = np.where(a[..., 3] > 127, 255, 0)
    # stepped fade: the last frames lose their lower half
    if f >= frames - 2:
        a[FS // 2 + (f - frames + 2) * 18:, :, 3] = 0
    return Image.fromarray(a)


def sheet(frames, path):
    w = FS * len(frames)
    img = Image.new("RGBA", (w, FS), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        img.paste(fr, (i * FS, 0))
    img.save(path)
    print("wrote", os.path.relpath(path, ROOT))


def main():
    os.makedirs(OUT, exist_ok=True)
    sheet([render_flame(f, RED) for f in range(FRAMES)], os.path.join(OUT, "flame.png"))
    sheet([render_flame(f, BLUE) for f in range(FRAMES)], os.path.join(OUT, "flame_blue.png"))
    sheet([render_ball(f, RED) for f in range(FRAMES)], os.path.join(OUT, "fireball.png"))
    sheet([render_ball(f, BLUE) for f in range(FRAMES)], os.path.join(OUT, "fireball_blue.png"))
    sheet([render_smoke(f) for f in range(6)], os.path.join(OUT, "smoke.png"))


if __name__ == "__main__":
    main()
