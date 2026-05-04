#!/usr/bin/env bash

FOCUSED_WS="$(aerospace list-workspaces --monitor focused --visible 2>/dev/null)"
VISIBLE_WS="$(aerospace list-workspaces --monitor all --visible 2>/dev/null)"
USED_WS="$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)"

args=()

contains() {
  case "$1" in
  *$'\n'"$2"$'\n'* | "$2"$'\n'* | *$'\n'"$2" | "$2") return 0 ;;
  *) return 1 ;;
  esac
}

for ws in 1 2 3 4 5 6 7 8 9 0; do
  if contains "$VISIBLE_WS" "$ws"; then
    if [ "$ws" = "$FOCUSED_WS" ]; then
      args+=(--set "workspace.$ws"
        drawing=on
        icon.color=0xff000000
        background.drawing=on
        background.color=0xffffffff)
    else
      args+=(--set "workspace.$ws"
        drawing=on
        icon.color=0xff000000
        background.drawing=on
        background.color=0x99ffffff)
    fi

  elif contains "$USED_WS" "$ws"; then
    args+=(--set "workspace.$ws"
      drawing=on
      icon.color=0xffffffff
      background.drawing=on
      background.color=0x40ffffff)

  else
    args+=(--set "workspace.$ws"
      drawing=off
      icon.color=0x88ffffff
      background.drawing=off)
  fi
done

sketchybar --animate tanh 3 "${args[@]}"
