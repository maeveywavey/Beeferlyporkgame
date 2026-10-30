#!/usr/bin/env python3
"""Repaint the character textures for the realistic, PS2-era look.

The outfit, skin and hair textures from the CC0 packs are clean and flat. This
pass gives them what painted textures of that era had (the reference is the
character texturing in Kengo: Master of Bushido):
  * fold shading: soft, mostly vertical light and dark streaks in cloth
  * seam and edge darkening where colour regions meet, like baked occlusion
  * fabric grain and a faint weave
  * wear: grime gathered in patches
  * a muted, slightly warm grade: less saturation, deeper darks
Skin gets gentle mottling and edge shading; hair gets strand streaks.

Reads the originals and writes assets/characters/painted/, so it can be re-run.
It also bakes the Hamakaze outfit textures (indigo and rust) from the old
peninsula recolours, since the game renamed that culture.

Usage: python3 tools/paint_textures.py
"""
import colorsys
import glob
import os

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAR = os.path.join(ROOT, "assets", "characters")
OUT = os.path.join(CHAR, "painted")
SIZE = 512
RNG = np.random.default_rng(7)


def blur(a, rx, ry=None):
    """Gaussian blur of a float image, anisotropic by resampling."""
    ry = rx if ry is None else ry
    h, w = a.shape[:2]
    k = max(rx, ry)
    img = Image.fromarray(np.clip(a * 255.0, 0, 255).astype(np.uint8))
    # squash the short axis so one isotropic blur becomes anisotropic
    sx, sy = max(1, int(w * k / rx)), max(1, int(h * k / ry))
    img = img.resize((sx, sy), Image.BILINEAR).filter(ImageFilter.GaussianBlur(k))
    return np.asarray(img.resize((w, h), Image.BILINEAR)).astype(np.float32) / 255.0


def noise(h, w, rx, ry=None):
    n = blur(RNG.random((h, w)).astype(np.float32), rx, ry)
    n -= n.min()
    return n / max(n.max(), 1e-6)


def edges(rgb):
    """Where colour regions meet: a soft mask, 1 at the boundary."""
    lum = rgb.mean(axis=2)
    gx = np.abs(np.diff(lum, axis=1, append=lum[:, -1:]))
    gy = np.abs(np.diff(lum, axis=0, append=lum[-1:, :]))
    e = np.clip((gx + gy) * 6.0, 0, 1)
    return np.clip(blur(e, 2.5) * 3.0, 0, 1)


def grade(rgb, sat=0.7, gamma=1.12, gain=0.94, warm=0.03):
    grey = rgb.mean(axis=2, keepdims=True)
    rgb = grey + (rgb - grey) * sat
    rgb = np.clip(rgb, 0, 1) ** gamma * gain
    rgb[..., 0] += warm * (1 - rgb[..., 0]) * 0.5
    rgb[..., 2] -= warm * rgb[..., 2] * 0.5
    return np.clip(rgb, 0, 1)


def load(path):
    img = Image.open(path).convert("RGBA").resize((SIZE, SIZE), Image.LANCZOS)
    a = np.asarray(img).astype(np.float32) / 255.0
    return a[..., :3].copy(), a[..., 3:].copy()


def save(rgb, alpha, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out = np.concatenate([np.clip(rgb, 0, 1), alpha], axis=2)
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(path, optimize=True)


def paint_cloth(rgb):
    h, w = rgb.shape[:2]
    folds = noise(h, w, 10, 34) * 0.7 + noise(h, w, 4, 12) * 0.3
    rgb = rgb * (0.8 + folds[..., None] * 0.36)
    rgb *= (1.0 - edges(rgb) * 0.32)[..., None]
    grain = RNG.random((h, w)).astype(np.float32)
    weave = (np.sin(np.arange(w) * 2.4)[None, :] * np.sin(np.arange(h) * 2.4)[:, None]) * 0.5 + 0.5
    rgb *= (0.95 + grain * 0.08 + weave * 0.03)[..., None]
    grime = np.clip((noise(h, w, 22) - 0.55) * 3.0, 0, 1)
    dirt = np.array([0.32, 0.27, 0.21], np.float32)
    rgb = rgb * (1 - grime[..., None] * 0.28) + dirt * grime[..., None] * 0.28
    return grade(rgb)


def paint_skin(rgb):
    h, w = rgb.shape[:2]
    mottle = noise(h, w, 12) * 0.6 + noise(h, w, 3) * 0.4
    rgb = rgb * (0.93 + mottle[..., None] * 0.12)
    rgb[..., 0] *= 1.0 + (noise(h, w, 18) - 0.5) * 0.06
    rgb *= (1.0 - edges(rgb) * 0.15)[..., None]
    return grade(rgb, sat=0.85, gamma=1.05, gain=0.97, warm=0.02)


def paint_hair(rgb):
    h, w = rgb.shape[:2]
    strands = noise(h, w, 1, 22) * 0.7 + noise(h, w, 1, 6) * 0.3
    rgb = rgb * (0.72 + strands[..., None] * 0.5)
    return grade(rgb, sat=0.8, gamma=1.15, gain=0.95, warm=0.0)


def hamakaze(rgb):
    """The old peninsula greens and golds become indigo and rust."""
    out = rgb.copy()
    flat = out.reshape(-1, 3)
    for i, (r, g, b) in enumerate(flat):
        hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
        if ss > 0.18 and 0.18 < hh < 0.5:      # greens -> indigo
            hh = 0.62
            ss *= 0.8
            ll *= 0.85
        elif ss > 0.25 and 0.08 < hh <= 0.18:  # golds -> rust
            hh = 0.04
            ss *= 0.8
        flat[i] = colorsys.hls_to_rgb(hh, ll, ss)
    return out


def main():
    culture = os.path.join(CHAR, "culture")
    for path in sorted(glob.glob(os.path.join(culture, "*.jpg"))):
        name = os.path.splitext(os.path.basename(path))[0]
        rgb, a = load(path)
        if name.endswith("_kyoshi"):
            rgb = hamakaze(rgb)
            name = name.replace("_kyoshi", "_hamakaze")
        save(paint_cloth(rgb), a, os.path.join(OUT, "culture", name + ".png"))
        print("cloth", name)
    for path in sorted(glob.glob(os.path.join(CHAR, "base", "T_Superhero_*.png"))):
        name = os.path.basename(path)
        if "Normal" in name or "Roughness" in name:
            continue
        rgb, a = load(path)
        save(paint_skin(rgb), a, os.path.join(OUT, "base", name))
        print("skin", name)
    for path in sorted(glob.glob(os.path.join(CHAR, "*", "T_Hair_*_BaseColor.png"))):
        rgb, a = load(path)
        save(paint_hair(rgb), a, os.path.join(OUT, "hair", os.path.basename(path)))
        print("hair", os.path.basename(path))


if __name__ == "__main__":
    main()
