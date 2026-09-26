#!/bin/bash
# Headless screenshot: shot.sh OUT [extra args...]
# e.g. shot.sh /data/shots/hero.png --cam=0,4,14 --look=0,2,0 --frames=110
set -e
OUT="$1"; shift
mkdir -p "$(dirname "$OUT")"
export XDG_RUNTIME_DIR=/tmp/xdg-runtime
mkdir -p "$XDG_RUNTIME_DIR"
xvfb-run -a --server-args="-screen 0 1280x720x24" \
  /data/bin/Godot_v4.7.2-stable_linux.x86_64 --path /data/my_game \
  --resolution 1280x720 --rendering-driver opengl3 \
  res://tools/shot.tscn -- --out="$OUT" "$@" 2>&1 | tail -4
