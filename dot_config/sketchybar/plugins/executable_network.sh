#!/bin/bash

source "${CONFIG_DIR:-$(cd "$(dirname "$0")/.." && pwd)}/plugins/common.sh"
export LC_ALL=C
set -o pipefail
init_state network || exit 1

IFACE="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2; exit}')"
if [[ -z "$IFACE" ]]; then
  IFACE="$(route -n get -inet6 default 2>/dev/null | awk '/interface:/ {print $2; exit}')"
fi

if [[ -z "$IFACE" ]]; then
  rm -f "$STATE_FILE"
  sketchybar --set "$NAME" label="offline"
  exit 0
fi

# Link rows are authoritative; IP rows repeat the same counters. Index from
# the right because tunnel interfaces omit the link-layer address column.
COUNTERS="$(netstat -ibn -I "$IFACE" 2>/dev/null | awk -v iface="$IFACE" '
  $1 == iface && $3 ~ /^<Link#/ {
    printf "%.0f %.0f\n", $(NF - 4), $(NF - 1)
    found = 1
    exit
  }
  END { if (!found) exit 1 }
')"
if [[ $? -ne 0 ]]; then
  rm -f "$STATE_FILE"
  sketchybar --set "$NAME" label="N/A"
  exit 0
fi
read -r RX_BYTES TX_BYTES <<< "$COUNTERS"
is_counter "$RX_BYTES" && is_counter "$TX_BYTES" || exit 1
NOW="$(date +%s)"

DOWN=0
UP=0
if [[ "${SENDER:-}" != system_woke && "${SENDER:-}" != forced && -f "$STATE_FILE" ]]; then
  read -r OLD_IFACE OLD_RX OLD_TX OLD_NOW EXTRA < "$STATE_FILE"
  if [[ "$OLD_IFACE" == "$IFACE" && -z "$EXTRA" ]] &&
     is_counter "$OLD_RX" && is_counter "$OLD_TX" && is_counter "$OLD_NOW"; then
    DT=$((NOW - OLD_NOW))
    # Long gaps (including sleep), clock changes and counter resets start fresh.
    if ((DT > 0 && DT <= NETWORK_INTERVAL * 4 && RX_BYTES >= OLD_RX && TX_BYTES >= OLD_TX)); then
      DOWN=$(((RX_BYTES - OLD_RX) / DT))
      UP=$(((TX_BYTES - OLD_TX) / DT))
    fi
  fi
fi
write_state "$IFACE" "$RX_BYTES" "$TX_BYTES" "$NOW" || exit 1

LABEL="$(awk -v down="$DOWN" -v up="$UP" '
  function fmt(bytes) {
    if (bytes >= 1073741824) return sprintf("%.1fGiB/s", bytes / 1073741824)
    if (bytes >= 1048576) return sprintf("%.1fMiB/s", bytes / 1048576)
    if (bytes >= 1024) return sprintf("%.0fKiB/s", bytes / 1024)
    return sprintf("%.0fB/s", bytes)
  }
  BEGIN { printf "↓%s ↑%s", fmt(down), fmt(up) }
')"
sketchybar --set "$NAME" label="$LABEL"
