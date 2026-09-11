#!/bin/bash

source "${CONFIG_DIR:-$(cd "$(dirname "$0")/.." && pwd)}/plugins/common.sh"
STEP=0
if [[ "${SENDER:-}" == mouse.scrolled ]]; then
  DELTA="${SCROLL_DELTA:-}"
  [[ "$DELTA" =~ ^[+-]?[0-9]+$ ]] || exit 0
  [[ "$DELTA" =~ ^[+-]?0+$ ]] && exit 0
  if [[ "$DELTA" == -* ]]; then
    STEP=$((-VOLUME_STEP))
  else
    STEP="$VOLUME_STEP"
  fi
fi

# Query mute as well as volume. A nonzero volume can still be muted. Scroll
# changes and the resulting read happen together, with no dependency on a
# follow-up event. The slow routine update catches missed mute notifications.
STATUS="$(osascript - "$STEP" <<'APPLESCRIPT'
on run argv
  set stepSize to (item 1 of argv) as integer
  if stepSize is not 0 then
    set newVolume to (output volume of (get volume settings)) + stepSize
    if newVolume < 0 then set newVolume to 0
    if newVolume > 100 then set newVolume to 100
    set volume output volume newVolume
  end if
  set currentSettings to get volume settings
  return ((output volume of currentSettings) as text) & " " & ((output muted of currentSettings) as text)
end run
APPLESCRIPT
)" || { sketchybar --set "$NAME" label="N/A"; exit 1; }
read -r VOLUME MUTED <<< "$STATUS"
if [[ "${SENDER:-}" == volume_change && "${INFO:-}" =~ ^[0-9]{1,3}$ ]]; then
  EVENT_VOLUME=$((10#$INFO))
  ((EVENT_VOLUME <= 100)) && VOLUME="$EVENT_VOLUME"
fi
is_counter "$VOLUME" && ((VOLUME <= 100)) || exit 1
[[ "$MUTED" == true || "$MUTED" == false ]] || exit 1

if [[ "$MUTED" == true ]] || ((VOLUME == 0)); then
  ICON="󰖁"
elif ((VOLUME >= 60)); then
  ICON="󰕾"
elif ((VOLUME >= 30)); then
  ICON="󰖀"
else
  ICON="󰕿"
fi
sketchybar --set "$NAME" icon="$ICON" label="$VOLUME%"
