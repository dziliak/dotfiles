#!/usr/bin/env bash

source "${CONFIG_DIR:-$(cd "$(dirname "$0")/.." && pwd)}/plugins/common.sh"

# Preserve the last good display if AeroSpace is restarting or unavailable.
FOCUSED_WS="$(aerospace list-workspaces --focused 2>/dev/null)" || exit 0
VISIBLE_WS="$(aerospace list-workspaces --monitor all --visible 2>/dev/null)" || exit 0
USED_WS="$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)" || exit 0
[[ -n "$FOCUSED_WS" && -n "$VISIBLE_WS" ]] || exit 0

args=()

contains() {
  [[ $'\n'"$1"$'\n' == *$'\n'"$2"$'\n'* ]]
}

for ws in "${WORKSPACES[@]}"; do
  if contains "$VISIBLE_WS" "$ws"; then
    if [ "$ws" = "$FOCUSED_WS" ]; then
      args+=(--set "workspace.$ws"
        drawing=on
        icon.color="$COLOR_DARK"
        background.drawing=on
        background.color="$COLOR_TEXT")
    else
      args+=(--set "workspace.$ws"
        drawing=on
        icon.color="$COLOR_DARK"
        background.drawing=on
        background.color="$COLOR_VISIBLE")
    fi

  elif contains "$USED_WS" "$ws"; then
    args+=(--set "workspace.$ws"
      drawing=on
      icon.color="$COLOR_TEXT"
      background.drawing=on
      background.color="$COLOR_OCCUPIED")

  else
    args+=(--set "workspace.$ws"
      drawing=off
      icon.color="$COLOR_INACTIVE"
      background.drawing=off)
  fi
done

sketchybar --animate tanh 3 "${args[@]}"
