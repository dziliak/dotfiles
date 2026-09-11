#!/bin/bash

source "${CONFIG_DIR:-$(cd "$(dirname "$0")/.." && pwd)}/plugins/common.sh"
init_state cpu || exit 1

# Build once per source change; the executable is machine-local cache data.
SOURCE="$CONFIG_DIR/helpers/cpu.c"
HELPER="$CACHE_DIR/cpu-counter"
if [[ ! -x "$HELPER" || "$SOURCE" -nt "$HELPER" ]]; then
  TEMPORARY="$(mktemp "$HELPER.XXXXXX")" || exit 1
  if ! xcrun clang -O2 -Wall -Wextra "$SOURCE" -o "$TEMPORARY"; then
    rm -f "$TEMPORARY"
    sketchybar --set "$NAME" label="N/A"
    exit 1
  fi
  mv -f "$TEMPORARY" "$HELPER" || exit 1
fi

COUNTERS="$("$HELPER")" || { sketchybar --set "$NAME" label="N/A"; exit 1; }
read -r BUSY IDLE NOW <<< "$COUNTERS"
is_counter "$BUSY" && is_counter "$IDLE" && is_counter "$NOW" || exit 1
LABEL="…"
if [[ "${SENDER:-}" != system_woke && "${SENDER:-}" != forced && -f "$STATE_FILE" ]]; then
  read -r OLD_BUSY OLD_IDLE OLD_NOW EXTRA < "$STATE_FILE"
  if [[ -z "$EXTRA" ]] && is_counter "$OLD_BUSY" && is_counter "$OLD_IDLE" && is_counter "$OLD_NOW"; then
    DT=$((NOW - OLD_NOW))
    if ((DT > 0 && DT <= CPU_INTERVAL * 4 && BUSY >= OLD_BUSY && IDLE >= OLD_IDLE)); then
      BUSY_DELTA=$((BUSY - OLD_BUSY))
      TOTAL=$((BUSY_DELTA + IDLE - OLD_IDLE))
      if ((TOTAL > 0)); then
        LABEL="$(((100 * BUSY_DELTA + TOTAL / 2) / TOTAL))%"
      fi
    fi
  fi
fi
write_state "$BUSY" "$IDLE" "$NOW" || exit 1
sketchybar --set "$NAME" label="$LABEL"
