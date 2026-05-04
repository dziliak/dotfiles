#!/usr/bin/env bash

STATE_FILE="/tmp/sketchybar_network_state"
IFACE="$(route get default 2>/dev/null | awk '/interface:/ {print $2}')"

[ -z "$IFACE" ] && {
  sketchybar --set "$NAME" label="offline"
  exit 0
}

RX_BYTES="$(netstat -ibn | awk -v iface="$IFACE" '$1 == iface {rx += $7; tx += $10} END {print rx+0}')"
TX_BYTES="$(netstat -ibn | awk -v iface="$IFACE" '$1 == iface {rx += $7; tx += $10} END {print tx+0}')"
NOW="$(date +%s)"

if [ -f "$STATE_FILE" ]; then
  read -r OLD_RX OLD_TX OLD_NOW < "$STATE_FILE"
  DT=$((NOW - OLD_NOW))
else
  OLD_RX="$RX_BYTES"
  OLD_TX="$TX_BYTES"
  DT=1
fi

echo "$RX_BYTES $TX_BYTES $NOW" > "$STATE_FILE"

[ "$DT" -le 0 ] && DT=1

DOWN=$(( (RX_BYTES - OLD_RX) / DT ))
UP=$(( (TX_BYTES - OLD_TX) / DT ))

fmt() {
  local bps="$1"

  if [ "$bps" -ge 1048576 ]; then
    awk -v v="$bps" 'BEGIN {printf "%.1fMB/s", v/1048576}'
  elif [ "$bps" -ge 1024 ]; then
    awk -v v="$bps" 'BEGIN {printf "%.0fKB/s", v/1024}'
  else
    printf "%dB/s" "$bps"
  fi
}

sketchybar --set "$NAME" label="↓$(fmt "$DOWN") ↑$(fmt "$UP")"
