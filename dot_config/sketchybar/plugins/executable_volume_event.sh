#!/usr/bin/env bash

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

case "$SENDER" in
mouse.scrolled)
  "$PLUGIN_DIR/volume_scroll.sh"
  "$PLUGIN_DIR/volume.sh"
  ;;
*)
  "$PLUGIN_DIR/volume.sh"
  ;;
esac
