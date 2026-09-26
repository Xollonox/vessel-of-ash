#!/usr/bin/env python3
"""Quantitative read of a game screenshot: luminance map, colour balance, detail."""
import sys
from PIL import Image, ImageFilter, ImageStat
import numpy as np

p = sys.argv[1]
im = Image.open(p).convert("RGB")
W, H = im.size
a = np.asarray(im).astype(np.float32)
lum = (0.2126*a[:,:,0] + 0.7152*a[:,:,1] + 0.0722*a[:,:,2])

print(f"== {p}  {W}x{H}")
print(f"luma mean={lum.mean():6.1f} p5={np.percentile(lum,5):6.1f} p50={np.percentile(lum,50):6.1f} "
      f"p95={np.percentile(lum,95):6.1f} max={lum.max():6.1f}")
print(f"clipped black(<4)={100*(lum<4).mean():5.2f}%  near-white(>250)={100*(lum>250).mean():5.2f}%")

# colour balance
warm = a[:,:,0].mean(); grn = a[:,:,1].mean(); cool = a[:,:,2].mean()
print(f"RGB means  R={warm:6.1f} G={grn:6.1f} B={cool:6.1f}   (R-B={warm-cool:+.1f})")

# edge energy -> "is there stuff to look at"
g = im.convert("L").filter(ImageFilter.FIND_EDGES)
e = np.asarray(g).astype(np.float32)
print(f"edge energy mean={e.mean():6.2f} p99={np.percentile(e,99):6.1f}")

def ascii_map(arr, cols=64, rows=22, ramp=" .:-=+*#%@"):
    h, w = arr.shape
    out = []
    for r in range(rows):
        line = ""
        for c in range(cols):
            blk = arr[r*h//rows:(r+1)*h//rows, c*w//cols:(c+1)*w//cols]
            v = blk.mean()/255.0
            line += ramp[min(len(ramp)-1, int(v*len(ramp)))]
        out.append(line)
    return "\n".join(out)

print("\n-- luminance map (dark -> bright) --")
print(ascii_map(lum))

# hue map: W=warm/orange, C=cool/blue, G=green, M=mid grey, . = dark
def hue_map(arr, cols=48, rows=16):
    h, w, _ = arr.shape
    out = []
    for r in range(rows):
        line = ""
        for c in range(cols):
            blk = arr[r*h//rows:(r+1)*h//rows, c*w//cols:(c+1)*w//cols].reshape(-1,3)
            m = blk.mean(axis=0)
            L = (0.2126*m[0]+0.7152*m[1]+0.0722*m[2])
            if L < 22: ch = "."
            elif L > 235: ch = "#"
            elif m[0]-m[2] > 18: ch = "W"
            elif m[2]-m[0] > 14: ch = "C"
            elif m[1]-max(m[0],m[2]) > 10: ch = "G"
            else: ch = "o"
            line += ch
        out.append(line)
    return "\n".join(out)

print("\n-- colour map (. dark, W warm, C cool, o neutral, # bright) --")
print(hue_map(a))

# region focus: where is the brightest warm blob (likely a light) and the player?
h, w = lum.shape
def stat(name, y0, y1, x0, x1):
    blk = lum[y0:y1, x0:x1]
    print(f"{name:16s} mean={blk.mean():6.1f} p95={np.percentile(blk,95):6.1f} contrast(sd)={blk.std():6.1f}")
print("\n-- region stats --")
stat("top third", 0, h//3, 0, w)
stat("middle third", h//3, 2*h//3, 0, w)
stat("bottom third", 2*h//3, h, 0, w)
stat("centre", h//3, 2*h//3, w//3, 2*w//3)
stat("left", 0, h, 0, w//3)
stat("right", 0, h, 2*w//3, w)
