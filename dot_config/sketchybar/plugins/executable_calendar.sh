#!/usr/bin/env bash

update_calendar() {
  sketchybar --set calendar label="$(date '+%a %b %d')"
  sketchybar --set calendar.month label="$(date '+%B %Y')"

  i=0

  while IFS= read -r row; do
    sketchybar --set "calendar.row.$i" \
      label="$row" \
      drawing=on
    i=$((i + 1))
  done < <(cal | tail -n +2)

  while [ "$i" -le 6 ]; do
    sketchybar --set "calendar.row.$i" \
      label="" \
      drawing=off
    i=$((i + 1))
  done
}

update_calendar

case "$1" in
toggle)
  sketchybar --set calendar popup.drawing=toggle
  ;;
esac
