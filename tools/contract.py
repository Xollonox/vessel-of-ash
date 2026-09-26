#!/usr/bin/env python3
"""Lighting contract check for a screenshot."""
import sys
import numpy as np
from PIL import Image, ImageFilter

p = sys.argv[1]
im = Image.open(p).convert("RGB")
a = np.asarray(im).astype(np.float32) / 255.0
lum = 0.2126 * a[:, :, 0] + 0.7152 * a[:, :, 1] + 0.0722 * a[:, :, 2]
med = float(np.median(lum))
nb = float((lum < 0.10).mean())
mid = float(((lum >= 0.10) & (lum <= 0.90)).mean())
blow = float((lum > 0.97).mean())
e = np.asarray(im.convert("L").filter(ImageFilter.FIND_EDGES)).astype(np.float32)
detail = float(e.mean())
checks = [
    ("median in 0.20-0.38", 0.20 <= med <= 0.38, f"median={med:.3f}"),
    ("near-black < 30%", nb < 0.30, f"near-black={nb*100:.1f}%"),
    ("mid-tone > 62%", mid > 0.62, f"mid-tone={mid*100:.1f}%"),
    ("blowout <= 2%", blow <= 0.02, f"blowout={blow*100:.2f}%"),
    ("has detail (edge energy > 2)", detail > 2.0, f"edge={detail:.2f}"),
]
ok = True
for name, passed, detail_s in checks:
    print(("PASS " if passed else "FAIL "), name, " ", detail_s)
    ok = ok and passed
print("CONTRACT:", "PASS" if ok else "FAIL")
sys.exit(0 if ok else 1)
