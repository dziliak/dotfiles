#!/bin/bash

source "${CONFIG_DIR:-$(cd "$(dirname "$0")/.." && pwd)}/plugins/common.sh"
# Arrow clicks have their own NAME, but all calendar items share one state.
NAME=calendar init_state calendar || exit 1
IFS='|' read -r TODAY DATE_LABEL MONTH YEAR <<< "$(date '+%Y-%m-%d|%a %b %d|%m|%Y')"
MONTH=$((10#$MONTH))
args=(--set calendar label="$DATE_LABEL")

LAST_DATE=""
SAVED_MONTH=""
SAVED_YEAR=""
[[ -f "$STATE_FILE" ]] && read -r LAST_DATE SAVED_MONTH SAVED_YEAR < "$STATE_FILE"
REFRESH=false
if [[ "$SAVED_MONTH" =~ ^([1-9]|1[0-2])$ && "$SAVED_YEAR" =~ ^[1-9][0-9]{0,3}$ ]]; then
  MONTH="$SAVED_MONTH"
  YEAR="$SAVED_YEAR"
else
  REFRESH=true
fi

OPENING=false
if [[ "${1:-}" == toggle ]]; then
  POPUP="$(sketchybar --query calendar | jq -er '.popup.drawing')" || exit 1
  if [[ "$POPUP" == on ]]; then
    args+=(--set calendar.month popup.drawing=off --set calendar popup.drawing=off)
  else
    OPENING=true
    args+=(--set calendar popup.drawing=on --set calendar.month popup.drawing=on)
  fi
fi

if [[ "$OPENING" == true || "${SENDER:-}" == forced ]]; then
  IFS=- read -r YEAR MONTH DAY <<< "$TODAY"
  MONTH=$((10#$MONTH))
  REFRESH=true
fi

case "${1:-}" in
  previous)
    if ((MONTH > 1)); then
      MONTH=$((MONTH - 1))
    elif ((YEAR > 1)); then
      MONTH=12
      YEAR=$((YEAR - 1))
    fi
    REFRESH=true
    ;;
  next)
    if ((MONTH < 12)); then
      MONTH=$((MONTH + 1))
    elif ((YEAR < 9999)); then
      MONTH=1
      YEAR=$((YEAR + 1))
    fi
    REFRESH=true
    ;;
esac

if [[ "$REFRESH" == true || "$LAST_DATE" != "$TODAY" ]]; then
  # Explicit month/year keeps the title and grid consistent at midnight.
  # -h suppresses terminal highlighting; SketchyBar renders plain text.
  GRID="$(LC_ALL=C cal -h "$MONTH" "$YEAR")" || exit 1
  MONTH_LABEL="${GRID%%$'\n'*}"
  MONTH_LABEL="${MONTH_LABEL#"${MONTH_LABEL%%[![:space:]]*}"}"
  MONTH_LABEL="${MONTH_LABEL%"${MONTH_LABEL##*[![:space:]]}"}"
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
  sketchybar "${args[@]}" && write_state "$TODAY $MONTH $YEAR"
else
  sketchybar "${args[@]}"
fi
