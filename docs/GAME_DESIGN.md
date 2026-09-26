# Vessel of Ash — Game Design

## Pitch

A 15–20 minute third-person action vertical slice. One descent, one goal, one boss.
The fantasy: a ruin-diver with a blade and no magic, fighting through an ossuary
that used to be a choir hall.

## Feel targets (the contract)

- **Weighty commitment.** Attacks have wind-up, active frames, and recovery. A
  whiffed swing plays a visible recovery clip; a connected swing flows back to
  idle. Mashing is punished by commitment, not by stamina bars.
- **Dodge i-frames on frame one.** Press dodge, and you are invulnerable that same
  frame. 0.5 s of grace, 0.55 s cooldown, 0.34 s of travel.
- **Parry that matters.** A 0.24 s parry window staggers the attacker and grants a
  free punish. Unblockable attacks (the Warden's grab, the Choir's finale) beat
  parry — dodge them instead.
- **Inputs buffer through hitstun.** Getting hit does not eat your inputs.
- **No phantom hits.** Every strike is a shape query gated by a facing cone
  (dot ≥ 0.30) and a line-of-sight raycast.

## Structure — The Cinderhold, seven beats

1. **Gate of Ash** — entry, tutorial-by-space. Two thralls. First checkpoint.
2. **The Long Descent** — 21 m grand staircase, arches, torchlight. Stalkers hunt
   you on the steps.
3. **Hall of Cinders** — pillared arena. Thralls and the first Warden (unblockable
   grab). Checkpoint.
4. **The Broken Gallery** — balcony corridor, arches, stalkers.
5. **The Ossuary Niche** — bone niches, cold light, ambush.
6. **The Vessel Chamber** — the Vessel of Ash on its pedestal. Checkpoint. Breathe.
7. **The Choir's Maw** — the gate seals. The Ossuary Choir waits on the dais.

## Enemies

| | HP | Damage | Behaviour |
| --- | --- | --- | --- |
| **Thrall** | 60 | 12 | Slow shambling swing, telegraphed |
| **Stalker** | 45 | 14 | Fast, lunges from range |
| **Warden** | 140 | 34 | Heavy, slow, **unblockable grab** |
| **The Ossuary Choir** | 600 | 18–34 | Boss, three phases |

### Boss — The Ossuary Choir

- **Phase 1 (600–396 HP):** conducting volleys (5–6 arcing bolts) alternating with
  melee swipes. Each move has its own wind-up silhouette.
- **Phase 2 (396–180):** summons two thralls from the ossuary; faster volleys.
- **Phase 3 (180–0):** enraged. Unblockable grabs, 8-bolt volleys, quicker swipes.
- Phase shifts roar, stagger the boss, and clear its attack queue.

## Player kit

- 100 HP, 5.6 m/s movement.
- Light combo A→B→C: 12 / 12 / 18 damage.
- Heavy: 30 damage, breaks guard (staggers enemies).
- Dodge: 12.5 m/s burst, i-frames from frame one.
- Parry: 0.24 s window, staggers attacker, fails vs unblockable.
- Lock-on: nearest enemy in front within 15 m.

## Technical pillars

- **Engine:** Godot 4.7, GL Compatibility (runs on anything, including software GL).
- **Light budget 28** — the Compatibility renderer drops every light past 32
  silently; `LevelKit.add_light()` enforces a hard budget so the level never
  goes dark.
- **Retargeted animation:** the Quaternius character rig and the UAL2 library share
  the same 65-bone skeleton, so animation retargeting is a deterministic path
  rewrite at load time (`scripts/util/animated_actor.gd`).
- **Level as code:** `tools/build_level.gd` generates the entire scene; the .tscn is
  a build artifact. Tune the generator, re-run, get a new level.
- **Audio as code:** `tools/gen_audio.py` synthesizes all 14 sounds.
