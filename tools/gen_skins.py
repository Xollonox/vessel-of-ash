#!/usr/bin/env python3
"""Generate recoloured character skin textures from the CC0 Quaternius base maps.
Writes assets/models/characters/skins/*.png (used by AnimatedActor.skin_texture)."""
import os
import numpy as np
from PIL import Image

SRC = "assets/models/characters"
OUT = os.path.join(SRC, "skins")

def load(name, fallback=None):
    path = os.path.join(SRC, name)
    if not os.path.exists(path) and fallback:
        print("missing", name, "- using", fallback)
        path = os.path.join(SRC, fallback)
    return np.asarray(Image.open(path).convert("RGB")).astype(np.float32) / 255.0

def save(arr, name, size=1024):
    os.makedirs(OUT, exist_ok=True)
    img = Image.fromarray((np.clip(arr, 0.0, 1.0) * 255.0).astype(np.uint8))
    if size and img.width > size:
        img = img.resize((size, size), Image.LANCZOS)
    img.save(os.path.join(OUT, name), optimize=True)
    print("wrote", os.path.join(OUT, name), img.size)

def noise(shape, scale=60.0, seed=1):
    rng = np.random.default_rng(seed)
    small = rng.random((max(2, int(shape[0] / scale)), max(2, int(shape[1] / scale)))).astype(np.float32)
    img = Image.fromarray((small * 255).astype(np.uint8)).resize((shape[1], shape[0]), Image.BICUBIC)
    return np.asarray(img).astype(np.float32) / 255.0

def mix(a, b, t):
    return a * (1.0 - t) + b * t

def tone(a, gain, lift, sat):
    g = a.mean(axis=2, keepdims=True)
    a = mix(a, g, 1.0 - sat)
    return a * gain + lift

male_dark = load("T_Superhero_Male_Dark.png")
male_light = load("T_Superhero_Male_Ligh.png", "T_Superhero_Male_Dark.png")
female_dark = load("T_Superhero_Female_Dark_BaseColor.png", "T_Superhero_Male_Dark.png")

# Kael - ash leather with a faint warm cast
kael = tone(male_dark, 0.82, -0.03, 0.82)
kael = mix(kael, np.array([0.36, 0.30, 0.24], np.float32), 0.22)
kael += (noise(kael.shape, 40, 3)[..., None] - 0.5) * 0.10
save(kael, "T_Male_KAEL.png")

# Thrall - corpse pale
thrall = tone(male_light, 0.78, 0.02, 0.45)
thrall = mix(thrall, np.array([0.42, 0.45, 0.42], np.float32), 0.35)
thrall += (noise(thrall.shape, 18, 5)[..., None] - 0.5) * 0.16
save(thrall, "T_Male_THRALL.png")

# Warden - iron with rust speckle
warden = tone(male_dark, 0.72, -0.02, 0.55)
warden = mix(warden, np.array([0.30, 0.32, 0.36], np.float32), 0.45)
rust = noise(warden.shape, 25, 7)
warden += (rust[..., None] > 0.62) * np.array([0.25, 0.10, 0.02], np.float32)
save(warden, "T_Male_WARDEN.png")

# Stalker - crimson
stalk = tone(female_dark, 0.85, -0.02, 0.9)
stalk = mix(stalk, np.array([0.45, 0.12, 0.12], np.float32), 0.42)
stalk += (noise(stalk.shape, 22, 11)[..., None] - 0.5) * 0.10
save(stalk, "T_Female_STALKER.png")

# Boss - charcoal with ember flecks
boss = tone(male_dark, 0.6, -0.02, 0.5)
boss = mix(boss, np.array([0.20, 0.18, 0.20], np.float32), 0.5)
fleck = noise(boss.shape, 14, 13)
boss += (fleck[..., None] > 0.80) * np.array([0.5, 0.22, 0.05], np.float32)
save(boss, "T_Male_BOSS.png")
