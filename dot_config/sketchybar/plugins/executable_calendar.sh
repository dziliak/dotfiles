#!/bin/bash

source "${CONFIG_DIR:-$(cd "$(dirname "$0")/.." && pwd)}/plugins/common.sh"
init_state calendar || exit 1
IFS='|' read -r TODAY DATE_LABEL MONTH_LABEL MONTH YEAR <<< "$(date '+%Y-%m-%d|%a %b %d|%B %Y|%m|%Y')"
args=(--set calendar label="$DATE_LABEL")

OPENING=false
if [[ "${1:-}" == toggle ]]; then
  POPUP="$(sketchybar --query calendar | jq -er '.popup.drawing')" || exit 1
  if [[ "$POPUP" == on ]]; then
    args+=(--set calendar popup.drawing=off)
  else
    OPENING=true
    args+=(--set calendar popup.drawing=on)
  fi
fi

LAST_DATE=""
[[ -f "$STATE_FILE" ]] && read -r LAST_DATE < "$STATE_FILE"
if [[ "$OPENING" == true || "$LAST_DATE" != "$TODAY" || "${SENDER:-}" == forced ]]; then
  # Explicit month/year keeps the title and grid consistent at midnight.
  # -h suppresses terminal highlighting; SketchyBar renders plain text.
  GRID="$(LC_ALL=C cal -h "$MONTH" "$YEAR")" || exit 1
  args+=(--set calendar.month label="$MONTH_LABEL")
  i=0
  while IFS= read -r row; do
    ((i <= 6)) || break
    if [[ "$row" == *[![:space:]]* ]]; then
      args+=(--set "calendar.row.$i" label="$row" drawing=on)
    else
      args+=(--set "calendar.row.$i" label="" drawing=off)
    fi
    i=$((i + 1))
  done <<< "${GRID#*$'\n'}"
  while ((i <= 6)); do
    args+=(--set "calendar.row.$i" label="" drawing=off)
    i=$((i + 1))
  done
  sketchybar "${args[@]}" && write_state "$TODAY"
else
  sketchybar "${args[@]}"
fi
