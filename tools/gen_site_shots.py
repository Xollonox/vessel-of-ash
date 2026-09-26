#!/usr/bin/env python3
"""Rebuild site/shots.js from the current screenshot set (base64 data URIs).
Usage: python3 tools/gen_site_shots.py
Screenshots live in /data/shots; missing ones are skipped."""
import base64, os, subprocess

SHOTS = {
    "hero":    "/data/shots/v04/skelclose.png",
    "hall":    "/data/shots/v04/hall2.png",
    "combat":  "/data/shots/v04/combat.png",
    "boss":    "/data/shots/v04/boss2.png",
    "gate":    "/data/shots/v04/gate2.png",
}
OUT_DIR = "site/img"

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    out = {}
    for k, p in SHOTS.items():
        if not os.path.exists(p):
            print("skip (missing):", p)
            continue
        jpg = os.path.join(OUT_DIR, k + ".jpg")
        subprocess.run(["magick", p, "-resize", "1024x576>", "-quality", "76", jpg], check=True)
        b64 = base64.b64encode(open(jpg, "rb").read()).decode()
        out[k] = b64
        print(f"{k}: {os.path.getsize(jpg)/1024:.0f} KB jpg")
    js = "// Vessel of Ash - inlined screenshots (base64 data URIs)\nconst SHOTS = {\n"
    for k, v in out.items():
        js += f'  {k}: "data:image/jpeg;base64,{v}",\n'
    js += "};\n"
    open("site/shots.js", "w").write(js)
    print("shots.js:", os.path.getsize("site/shots.js") // 1024, "KB")

if __name__ == "__main__":
    main()
