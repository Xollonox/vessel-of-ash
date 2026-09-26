#!/bin/bash
# Installs the Godot 4.7.2 export templates from /data/dl/templates.tpz
# (or downloads them if missing). Needed after a sandbox reset.
set -e
V=4.7.2.stable
TPZ=/data/dl/templates.tpz
DEST="$HOME/.local/share/godot/export_templates/$V"
if [ -f "$DEST/web_nothreads_release.zip" ]; then
  echo "templates already installed"; exit 0
fi
if [ ! -f "$TPZ" ]; then
  mkdir -p /data/dl
  wget -q -O "$TPZ" "https://github.com/godotengine/godot/releases/download/${V%-*}-stable/Godot_v${V%-*}-stable_export_templates.tpz"
fi
mkdir -p "$DEST"
cd /tmp && rm -rf tpl && mkdir tpl && cd tpl
unzip -q "$TPZ"
mv templates/* "$DEST/"
echo "templates installed to $DEST"
