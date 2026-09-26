# Vessel of Ash

**▶ Play in your browser: https://xollonox.github.io/vessel-of-ash/**
**⬇ Downloads: https://github.com/Xollonox/vessel-of-ash/releases/latest**

A third-person action vertical slice built with **Godot 4.7** (Compatibility renderer).
God of War 2018 / Resident Evil 4 Remake feel — weighty melee, committed swings,
dodge i-frames, parries that stagger, and a three-phase boss at the bottom of a
21-metre descent.

You are **Kael Ardyn**, descending into **The Cinderhold** to silence
**The Ossuary Choir** and reclaim the Vessel of Ash.

## Controls

| Action | Input |
| --- | --- |
| Move | WASD / arrows / left stick |
| Camera | Mouse / right stick |
| Light attack (3-hit combo) | J / left mouse / X |
| Heavy attack | K / right mouse / Y |
| Parry | L / B |
| Dodge (i-frames frame one) | Space / A |
| Lock on | Q / middle mouse |
| Interact | E |
| Touch | virtual stick (left) · drag right side to look · on-screen buttons |

## Run it

```bash
godot --path .                 # title screen → ENTER THE CINDERHOLD
godot --path . res://scenes/level_01.tscn
```

First clone: fetch the CC0 assets (characters + animation library), then import:

```bash
bash tools/fetch_assets.sh
godot --headless --path . --import
```

## Tooling

```bash
# regenerate the level scene from code
godot --headless --path . res://tools/build_level.tscn

# 20-check gameplay test suite
godot --headless --path . res://tools/playtest.tscn

# regenerate the SFX set (procedural, numpy)
python3 tools/gen_audio.py

# headless screenshots
./tools/shot.sh /data/shots/hero.png --cam=0,3.2,11 --look=0,1.2,1
./tools/shot.sh /data/shots/combat.png --cam=2.6,1.75,-0.75 --look=0,1.1,-0.75 --combat

# gear tuning close-ups (weapon socket transforms)
RES=1280x720 ./tools/gear.sh /data/shots/gear.png --rot=-90,0,0 --clip=Sword_Regular_A

# regenerate the recoloured character skins
python3 tools/gen_skins.py

# install export templates after a sandbox reset
bash tools/install_templates.sh

# lighting contract check on a screenshot
python3 tools/contract.py /data/shots/hero.png
```

## Design notes

- **Deterministic combat**: all hits are `intersect_shape()` queries gated by facing
  cones and line-of-sight raycasts. No area-overlap hit detection anywhere.
- **Light budget 28**: Godot's Compatibility renderer silently drops every light past
  32. Every light goes through `LevelKit.add_light()` with a hard budget guard.
- **Real character**: Quaternius Universal Base Characters (65-bone rig) with the
  Universal Animation Library 2 (43 clips) retargeted at load time.
- **Input buffering** survives hitstun; whiffed swings carry recovery, connected
  swings flow straight back to idle.
- **Game feel**: hit-stop on connect (heavier on heavy attacks), blade trails,
  slash crescents, impact sparks, enemy hit-flash, camera shake + FOV punch, and an
  ember telegraph for unblockable attacks.
- **Gear**: KayKit CC0 weapons socketed to the hand bone, Quaternius hairstyles
  posed onto the head each frame, and hand-tinted armour textures per character
  (`tools/gen_skins.py`).
- **Touch**: a virtual joystick + action buttons (`scripts/ui/touch_controls.gd`)
  that drive the same Input actions as the keyboard — phones and tablets work.

## CI

Every push to `main` runs the full pipeline in `.github/workflows/deploy.yml`:
fetch assets → import → **20-check playtest** → export Web + Linux + Windows →
publish the browser build to GitHub Pages → attach desktop builds to a release.

## Credits

Characters & animation: [Quaternius](https://quaternius.com) Universal Base Characters
and Universal Animation Library 2 — CC0. See `docs/CREDITS.md`.
