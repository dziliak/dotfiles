#!/bin/bash

source "${CONFIG_DIR:-$(cd "$(dirname "$0")/.." && pwd)}/plugins/common.sh"
STATUS="$(pmset -g batt)" || exit 1

if [[ "$STATUS" =~ ([0-9]{1,3})% ]]; then
  PERCENTAGE=$((10#${BASH_REMATCH[1]}))
  ((PERCENTAGE <= 100)) || exit 1
else
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

case "$PERCENTAGE" in
  9[0-9]|100) ICON="" ;;
  [6-8][0-9]) ICON="" ;;
  [3-5][0-9]) ICON="" ;;
  [1-2][0-9]) ICON="" ;;
  *) ICON="" ;;
esac

COLOR="$COLOR_TEXT"
if [[ "$STATUS" == *'; charging;'* ]]; then
  ICON=""
  COLOR="$COLOR_CHARGING"
elif [[ "$STATUS" == *"'AC Power'"* ]]; then
  ICON=""
elif ((PERCENTAGE <= LOW_BATTERY_PERCENT)); then
  COLOR="$COLOR_WARNING"
fi

sketchybar --set "$NAME" drawing=on icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
