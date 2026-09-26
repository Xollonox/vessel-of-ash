#!/bin/bash
# Gear tuning screenshot: gear.sh OUT [extra args...]
set -e
OUT="$1"; shift
mkdir -p "$(dirname "$OUT")"
export XDG_RUNTIME_DIR=/tmp/xdg-runtime
mkdir -p "$XDG_RUNTIME_DIR"
RES="${RES:-1280x720}"
xvfb-run -a --server-args="-screen 0 ${RES}x24" \
  /data/bin/Godot_v4.7.2-stable_linux.x86_64 --path /data/my_game \
  --resolution "${RES}" --rendering-driver opengl3 \
  res://tools/gear_shot.tscn -- --out="$OUT" "$@" 2>&1 | tail -3
