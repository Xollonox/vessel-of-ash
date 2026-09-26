#!/bin/bash
# Downloads the CC0 assets (Quaternius Universal Base Characters + UAL2) into
# assets/. Run from the repo root: bash tools/fetch_assets.sh
set -e
R="NafisRayan/Animate-Rigged-Humanoid-No-Blender"
B="Universal%20Base%20Characters%5BStandard%5D/Universal%20Base%20Characters%5BStandard%5D/Base%20Characters/Godot%20-%20UE"
mkdir -p assets/models/characters assets/animations
cd assets/models/characters
for f in Superhero_Male_FullBody.gltf Superhero_Male_FullBody.bin \
         Superhero_Female_FullBody.gltf Superhero_Female_FullBody.bin \
         T_Eye_Brown.png T_Eye_Normal.png T_Hair_1_BaseColor.png T_Hair_1_Normal.png \
         T_Hair_2_BaseColor.png T_Hair_2_Normal.png \
         T_Superhero_Male_Dark.png T_Superhero_Male_Normal.png T_Superhero_Male_Roughness.png \
         T_Superhero_Female_Dark_BaseColor.png T_Superhero_Female_Normal.png T_Superhero_Female_Roughness.png; do
  curl -sL -o "$f" "https://raw.githubusercontent.com/$R/main/$B/$f"
done
cp T_Eye_Normal.png T_Eye_Normal_png.png
cp T_Hair_1_Normal.png T_Hair_1_Normal_png.png
cd ../animations
curl -sL -o UAL2_Standard.glb "https://raw.githubusercontent.com/$R/main/Universal%20Animation%20Library%202%5BStandard%5D/Universal%20Animation%20Library%202%5BStandard%5D/Unreal-Godot/UAL2_Standard.glb"
echo "assets fetched (CC0, Quaternius)"
