#!/bin/bash

source "${CONFIG_DIR:-$(cd "$(dirname "$0")/.." && pwd)}/plugins/common.sh"
set -o pipefail

# Keep the last good list if AeroSpace is temporarily unavailable.
WINDOWS="$(aerospace list-windows --workspace focused --json 2>/dev/null)" || exit 0
APPS="$(jq -r '[.[]."app-name"] | unique | sort_by(ascii_downcase) | .[]' <<< "$WINDOWS")" || exit 0
FOCUSED_APP="$(aerospace list-windows --focused --json 2>/dev/null |
  jq -r '.[0]."app-name" // empty')" || FOCUSED_APP=""
EXISTING="$(sketchybar --query bar |
  jq -r '.items[] | select(test("^front_app\\.app\\.[0-9]+$"))')" || exit 0

args=(--set chevron drawing=off)
previous=front_app
count=0
while IFS= read -r app; do
  [[ -n "$app" ]] || continue
  item="front_app.app.$count"
  if [[ $'\n'"$EXISTING"$'\n' != *$'\n'"$item"$'\n'* ]]; then
    args+=(--add item "$item" left)
  fi

  font="$FONT_LABEL"
  [[ "$app" == "$FOCUSED_APP" ]] && font="${FONT_LABEL/:Regular:/:Bold:}"
  separator=on
  ((count == 0)) && separator=off
  args+=(--set "$item"
    drawing=on
    padding_left=0
    padding_right=0
    icon="|"
    icon.drawing="$separator"
    icon.font="$FONT_LABEL"
    icon.padding_right=12
    label="$app"
    label.font="$font"
    --move "$item" after "$previous")
  previous="$item"
  count=$((count + 1))
done <<< "$APPS"

# Remove leftover entries when the workspace has fewer apps (or is empty).
while IFS= read -r item; do
  [[ -n "$item" ]] || continue
  index="${item##*.}"
  if ((index >= count)); then
    args+=(--remove "$item")
  fi
done <<< "$EXISTING"
((count > 0)) && args+=(--set chevron drawing=on)

sketchybar "${args[@]}"
