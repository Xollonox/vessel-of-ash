# Vessel of Ash — Progress & How to Resume

## State: playable vertical slice, 33/33 automated checks green, published

- **Browser build (GitHub Pages):** https://xollonox.github.io/vessel-of-ash/
- **Public repo:** https://github.com/Xollonox/vessel-of-ash
- **CI:** `.github/workflows/deploy.yml` — fetch assets → import → playtest → export
  Web + Linux + Windows → deploy to Pages → attach desktop builds to a release.

## v0.5 additions (score + boss spectacle + combat depth)

- **Original score** (`tools/gen_audio.py`): a 12 s wind/rumble ambient bed, a 20 s
  crypt drone with struck bells, and a 16 s 160 bpm Choir theme (kick + off-beat
  tick + rising drone). `AudioManager.play_music()` crossfades beds over 1.6 s;
  `scripts/level/level.gd` starts the crypt bed on wake-up and switches to the
  Choir theme when the boss aggros. The workflow now runs `gen_audio.py` so CI
  builds ship the score.
- **Boss**: rebuilt on the skeleton rig (the old UAL2 clip names no longer existed).
  New **slam** move with an expanding ground-ring telegraph (`Fx.ring`) and a
  5.4 m radius check, bone volleys, summons (phase 3 also summons stalkers), and
  the boss now rises with `Skeletons_Awaken_Standing`.
- **Combat depth**: heavy chains into a heavy finisher (30 + 22, bigger hit-stop and
  FOV punch), sprinting + light fires a lunging running slash (20 dmg, 6.4 m lunge),
  on-screen combo counter driven by `Hud.register_hit()`.
- **Enemy personality**: wardens feint the overhead into a fast poke (34 % of the
  time), ranged mages blink 6 m away when the player closes inside 72 % of their
  keep-away band (4 s cooldown, ring + spark VFX at both ends).
- **Touch**: pushing the virtual stick past 88 % of its radius sprints.

## v0.4 additions (skeleton legions + architecture + feel)

- **Skeleton enemies**: KayKit Character Pack Skeletons (CC0) — four models
  (Minion / Rogue / Warrior / Mage), each with a 41-bone rig and **95 baked clips**.
  `scripts/util/skeleton_actor.gd` wraps them behind the same surface as
  `AnimatedActor`, so the AI code is unchanged.
  - thrall → Skeleton_Minion (blade), stalker → Skeleton_Rogue (blade, unblockable stab),
    warden → Skeleton_Warrior (axe, 2H), **mage → Skeleton_Mage (staff, ranged)**
  - `Skeletons_Awaken_Floor` plays the first time an enemy notices you (new RISE state)
  - per-class Hit / Death clips; corpses linger 2.3 s then shrink out
- **Ranged class**: the Ossuary Mage keeps a 6.5–13 m band, retreats when crowded,
  casts `Spellcast_Shoot` and lobs an arcing `VolleyBolt` at the player.
- **Controls**: sprint (Shift / L3, 7.6 m/s with camera FOV kick), lock-on target
  cycling, dodge/parry/heavy cancel windows after the hit frame, wider pitch clamp,
  smoother wall pull-in on the camera (snap in, ease out), gamepad right-stick look.
- **World building**: the whole level is dressed with the KayKit Dungeon Remastered
  modular kit on its 4 m grid — textured floor tiles (tile / dirt / wood / grate
  families with wear variants), 4 m wall slabs with arched bays, corridor walls
  stepping down the Long Descent, balcony rails, door gaps, crates/trunks/shelves/
  candles/keys/bottles and drifting ash motes in every room.
- **Graphics**: ACES tonemap, additive bloom (level-weighted), denser fog, brighter
  torches, shadow-casting braziers in the Choir's Maw, 8 torches down the descent.
  Light budget 30 → 31.

## v0.3 additions (touch + gear + world)

- **Touch controls** (`scripts/ui/touch_controls.gd`): floating virtual joystick
  (analog strength on the move actions), six action buttons, drag-to-look on the
  right half, auto-shows on touchscreens / first touch event. Verified in a real
  browser with touch emulation.
- **Weapons**: KayKit CC0 sword/dagger/2-handed sword socketed to `hand_r` with a
  `BoneAttachment3D`; blade trail sampled from a tip marker during swings
  (`scripts/fx/trail.gd`). Heavy attack now uses `Sword_Heavy_Combo`.
- **Hair + tinted armour**: Quaternius hairstyles are posed by copying bone poses
  onto the hair skeleton every frame; `tools/gen_skins.py` bakes five recoloured
  1024² armour textures (Kael / Thrall / Stalker / Warden / Boss).
- **World dressing**: ~50 KayKit dungeon props (pillars, banners, torches, chests,
  barrels, shelves, candles, spike traps, sword displays) + drifting ember
  particles in every room; light budget raised to 30.
- **Real SFX**: Kenney CC0 impact + RPG packs wired into swings, hits, parry,
  footsteps, dodges, telegraphs and deaths, with procedural fallbacks.
- **Movement**: walk speed 5.6 → 5.9, acceleration 34 → 38.

## Verified

- `tools/playtest.tscn` — **33/33 passing** (movement, camera-relative input,
  dodge i-frames frame one, combo 12/12/18, heavy 30, front-arc only, enemy cone,
  LOS blocking, parry stagger, unblockable beats parry, hit-stop freeze + restore,
  slash VFX spawn, stalker unblockable leap, weapon+hair gear, touch joystick +
  button, blade trail, enemy death cleanup, checkpoint heal + respawn, boss phase
  transitions).
- Web export boots in a browser (WebGL2 / Compatibility, single-threaded build).
- Level generates clean: 31/31 lights used, ~340 KB scene.
- All 43 UAL2 clips retarget onto the 65-bone character with 0 tracks dropped.

## Game-feel layer (v0.2 polish)

- `Juice.hitstop(duration, scale)` — autoload; freezes `Engine.time_scale` briefly on
  impact (0.055 s light / 0.10 s heavy / 0.13 s parry), restores with a generation
  guard so overlapping calls can't strand the time scale.
- `Fx.sparks(...)` / `Fx.slash(...)` — one-shot CPUParticles + procedurally built
  crescent meshes, all parented into the "fx" group (tests assert on it).
- Player: slash arc on every swing, sparks + hit-stop + camera FOV punch on connect,
  gold burst on parry, red burst on taking a hit / death.
- Enemies: white hit-flash + scale punch on damage, ember burst + lower-pitched
  telegraph for the **stalker's unblockable leap** (every 3rd attack, `cfg.alt`),
  boss unblockable grab telegraph + death burst.

## How to run everything

```bash
GODOT=/data/bin/Godot_v4.7.2-stable_linux.x86_64   # Godot 4.7.2

$GODOT --headless --path /data/my_game --import                      # reimport assets
$GODOT --headless --path /data/my_game res://tools/build_level.tscn  # regenerate level
$GODOT --headless --path /data/my_game res://tools/playtest.tscn     # 20 checks
python3 /data/my_game/tools/gen_audio.py                             # regenerate SFX
/data/my_game/tools/shot.sh /data/shots/hero.png --cam=0,3.2,11 --look=0,1.2,1
/data/my_game/tools/shot.sh /data/shots/combat.png --cam=2.6,1.75,-0.75 --look=0,1.1,-0.75 --combat
python3 /data/my_game/tools/contract.py /data/shots/hero.png         # lighting contract
```

Screenshots need `xvfb-run` + Mesa (`sudo dnf install xorg-x11-server-Xvfb mesa-libGL
mesa-libEGL mesa-dri-drivers libXcursor libXinerama libXrandr libXi libXext`).
One 1280x720 frame on llvmpipe takes roughly a minute.

Web export (needs `web_nothreads_release` template — thread_support off so it works
on GitHub Pages without COOP/COEP headers):

```bash
$GODOT --headless --path /data/my_game --export-release "Web" /data/my_game/builds/web/index.html
```

## File map

```
project.godot                  autoloads: InputSetup, AudioManager, Juice
scripts/player/player.gd       combat, buffering, dodge/parry, hit-stop wiring
scripts/player/camera_rig.gd   third-person camera, lock-on framing, shake, FOV punch
scripts/util/juice.gd          hit-stop autoload
scripts/fx/fx.gd               sparks / slash crescent factory
scripts/util/animated_actor.gd 65-bone model + UAL2 retarget + hit-flash
scripts/enemies/enemy_base.gd  thrall/stalker/warden AI + stalker unblockable leap
scripts/enemies/boss_choir.gd  three-phase boss (+ unblockable telegraph)
scripts/level/level.gd         beats, checkpoints, respawn, victory
scripts/ui/hud.gd              health, boss bar, toasts, overlays
site/                          GitHub Pages landing page (screenshots inlined in shots.js)
.github/workflows/deploy.yml   CI: playtest → exports → Pages → release
tools/build_level.gd           the Cinderhold generator (edit this, not the tscn)
tools/playtest.gd              20 automated checks
tools/shot.gd                  headless screenshots (--combat for a VFX frame)
```

## Next steps (in priority order)

1. Full-level traversal + boss fight end-to-end playtest on a real display.
2. More enemy variety in attack patterns; a warden variant that feints.
3. Weapon trail on the character's swing arm; footstep dust.
4. Trim the web build (63 MB) — drop unused textures, downscale PBR maps.

## Publishing notes

GitHub Pages must be enabled once by hand (GitHub won't let the workflow's token create
it): repo **Settings → Pages → Source = GitHub Actions**. After that every push to `main`
re-deploys automatically.
