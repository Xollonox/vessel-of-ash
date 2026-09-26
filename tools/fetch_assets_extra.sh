#!/bin/bash
# Extra CC0 assets: KayKit weapons + dungeon props, Quaternius hairstyles,
# Kenney impact + RPG sound packs. Run from the repo root.
set -e
KKA="https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0/main/addons/kaykit_character_pack_adventures/Assets/gltf"
KKD="https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0/main/addons/kaykit_dungeon_remastered/Assets/gltf"
HAIR="https://raw.githubusercontent.com/NafisRayan/Animate-Rigged-Humanoid-No-Blender/main/Universal%20Base%20Characters%5BStandard%5D/Universal%20Base%20Characters%5BStandard%5D/Hairstyles/Rigged%20to%20Head%20Bone/glTF%20(Godot%20-Unreal)"
KIMP="https://raw.githubusercontent.com/Boyquotes/kenney-impact-sounds-for-godot/main/addons/kenney%20impact%20sounds"
KRPG="https://raw.githubusercontent.com/Boyquotes/kenney-rpg-audio-for-godot/main/addons/kenney%20rpg%20audio"

mkdir -p assets/weapons assets/props/dungeon assets/hair assets/audio_kenney

echo "-- weapons (KayKit adventures)"
cd assets/weapons
for f in sword_1handed.gltf sword_1handed.bin sword_2handed.gltf sword_2handed.bin dagger.gltf dagger.bin; do
  curl -sfL -o "$f" "$KKA/$f"
done
cd ../..

echo "-- dungeon props (KayKit)"
cd assets/props/dungeon
for f in torch_lit.gltf.glb torch_mounted.gltf.glb pillar.gltf.glb pillar_decorated.gltf.glb \
         column.gltf.glb wall_arched.gltf.glb wall_doorway_sides.gltf.glb wall_gated.gltf.glb \
         wall_pillar.gltf.glb rubble_large.gltf.glb rubble_half.gltf.glb \
         sword_shield.gltf.glb sword_shield_gold.gltf.glb \
         banner_patternA_red.gltf.glb banner_thin_red.gltf.glb banner_patternC_white.gltf.glb \
         banner_shield_red.gltf.glb candle_triple.gltf.glb candle_lit.gltf.glb candle_melted.gltf.glb \
         chest.glb chest_gold.glb barrel_small.gltf.glb barrel_large.gltf.glb \
         crates_stacked.gltf.glb box_stacked.gltf.glb shelf_large.gltf.glb \
         floor_tile_big_spikes.glb coin_stack_large.gltf.glb coin_stack_small.gltf.glb; do
  curl -sfL -o "$f" "$KKD/$f"
done
cd ../../..

echo "-- hairstyles (Quaternius)"
cd assets/hair
for f in Hair_SimpleParted.gltf Hair_SimpleParted.bin Hair_Buzzed.gltf Hair_Buzzed.bin \
         Hair_Beard.gltf Hair_Beard.bin Hair_Long.gltf Hair_Long.bin \
         T_Hair_1_BaseColor.png T_Hair_1_Normal.png T_Hair_2_BaseColor.png T_Hair_2_Normal.png; do
  curl -sfL -o "$f" "$HAIR/$f"
done
cd ../..

echo "-- sound effects (Kenney impact + RPG)"
cd assets/audio_kenney
for f in impact_metal_heavy_000.ogg impact_metal_heavy_001.ogg impact_metal_heavy_003.ogg \
         impact_metal_light_000.ogg impact_metal_light_001.ogg \
         impact_generic_light_000.ogg impact_generic_light_002.ogg \
         impact_bell_heavy_000.ogg impact_bell_heavy_001.ogg impact_bell_heavy_002.ogg \
         footstep_concrete_000.ogg footstep_concrete_001.ogg footstep_concrete_002.ogg footstep_concrete_003.ogg \
         footstep_wood_000.ogg footstep_wood_001.ogg; do
  curl -sfL -o "$f" "$KIMP/$f"
done
for f in knife_slice.ogg knife_slice_2.ogg draw_knife_1.ogg draw_knife_2.ogg \
         metal_click.ogg metal_latch.ogg cloth_1.ogg cloth_2.ogg cloth_3.ogg \
         creak_1.ogg creak_2.ogg creak_3.ogg door_open_1.ogg door_close_1.ogg \
         footstep_0.ogg footstep_1.ogg footstep_2.ogg footstep_3.ogg; do
  curl -sfL -o "$f" "$KRPG/$f"
done
cd ../..

echo "-- licenses"
curl -sfL -o assets/props/dungeon/LICENSE_kaykit.txt "https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0/main/LICENSE.txt" || true
curl -sfL -o assets/weapons/LICENSE_kaykit.txt "https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0/main/LICENSE.txt" || true
curl -sfL -o assets/audio_kenney/LICENSE_kenney.txt "https://raw.githubusercontent.com/Boyquotes/kenney-rpg-audio-for-godot/main/LICENSE" || true
curl -sfL -o assets/hair/LICENSE_quaternius.txt "https://raw.githubusercontent.com/NafisRayan/Animate-Rigged-Humanoid-No-Blender/main/Universal%20Base%20Characters%5BStandard%5D/Universal%20Base%20Characters%5BStandard%5D/License_Standard.txt" || true

echo "extra assets fetched (CC0: KayKit, Kenney, Quaternius)"
