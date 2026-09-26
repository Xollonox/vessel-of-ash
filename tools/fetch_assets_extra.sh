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
# KayKit mixes two extensions inside one pack (.gltf.glb and .glb), so try both.
get_prop() {
  local base="$1"
  if [ -f "${base}.gltf.glb" ] || [ -f "${base}.glb" ]; then return 0; fi
  curl -sfL -o "${base}.gltf.glb" "$KKD/${base}.gltf.glb" && return 0
  curl -sfL -o "${base}.glb" "$KKD/${base}.glb" && return 0
  echo "   !! missing prop ${base}"
  return 0
}
for f in torch_lit torch_mounted torch \
         pillar pillar_decorated column \
         wall wall_arched wall_archedwindow_open \
         wall_doorway wall_doorway_sides wall_gated \
         wall_corner wall_corner_small wall_half \
         wall_pillar wall_window_open wall_broken \
         wall_crossing wall_endcap wall_Tsplit \
         floor_tile_large floor_tile_small \
         floor_tile_small_decorated floor_tile_small_broken_A \
         floor_tile_small_broken_B floor_tile_small_weeds_A \
         floor_tile_large_rocks floor_tile_big_grate \
         floor_tile_grate floor_tile_big_spikes \
         floor_wood_large floor_wood_large_dark \
         floor_wood_small floor_dirt_large \
         floor_dirt_large_rocky \
         stairs stairs_wide stairs_narrow \
         stairs_walled stairs_wood stairs_wood_decorated \
         barrier barrier_half barrier_column \
         barrier_corner \
         rubble_large rubble_half \
         sword_shield sword_shield_gold sword_shield_broken \
         banner_patternA_red banner_thin_red banner_patternC_white \
         banner_shield_red banner_triple_red \
         candle_triple candle_lit candle_melted candle_thin_lit \
         chest chest_gold barrel_small barrel_large \
         barrel_small_stack barrel_large_decorated keg \
         crates_stacked box_stacked box_large box_small \
         shelf_large shelf_small shelves \
         table_long table_long_broken table_medium \
         table_small chair stool \
         trunk_large_A trunk_medium_B trunk_small_C \
         bed_decorated bed_floor \
         coin_stack_large coin_stack_medium coin_stack_small \
         coin key keyring keyring_hanging \
         plate plate_food_A plate_small \
         bottle_A_brown bottle_A_green \
         bottle_B_brown bottle_B_green \
         bottle_C_brown bottle_C_green; do
  get_prop "$f"
done
cd ../../..

echo "-- skeleton characters (KayKit skeletons)"
mkdir -p assets/models/skeletons assets/weapons/skeleton
KS="https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0/main/addons/kaykit_character_pack_skeletons"
cd assets/models/skeletons
for f in Skeleton_Warrior.glb Skeleton_Rogue.glb Skeleton_Minion.glb Skeleton_Mage.glb skeleton_texture.png; do
  curl -sfL -o "$f" "$KS/Characters/gltf/$f"
done
curl -sfL -o LICENSE.txt "https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0/main/LICENSE.txt"
cd ../../..
cd assets/weapons/skeleton
for f in Skeleton_Axe Skeleton_Blade Skeleton_Staff Skeleton_Shield_Large_A \
         Skeleton_Shield_Small_A Skeleton_Crossbow Skeleton_Arrow Skeleton_Quiver; do
  curl -sfL -o "$f.gltf" "$KS/Assets/gltf/$f.gltf"
  curl -sfL -o "$f.bin" "$KS/Assets/gltf/$f.bin"
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
