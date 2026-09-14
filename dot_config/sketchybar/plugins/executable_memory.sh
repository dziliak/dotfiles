#!/bin/bash

source "${CONFIG_DIR:-$(cd "$(dirname "$0")/.." && pwd)}/plugins/common.sh"
export LC_ALL=C
NAME="${NAME:-memory}"

case "${SENDER:-}" in
  mouse.exited|mouse.exited.global)
    sketchybar --set "$NAME" popup.drawing=off
    exit 0
    ;;
  mouse.entered) sketchybar --set "$NAME" popup.drawing=on ;;
esac

unavailable() {
  sketchybar --set "$NAME" label="N/A" icon.color="$COLOR_INACTIVE" \
    --set memory.swap label="Swap: N/A" \
    --set memory.pressure label="Pressure: Unknown" label.color="$COLOR_INACTIVE"
  exit 1
}

VM_STATS="$(vm_stat)" || unavailable
SYSTEM_STATS="$(sysctl hw.memsize vm.swapusage)" || unavailable
PRESSURE="$(sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null)"

# Activity Monitor-style used RAM: anonymous + wired + physical compressor
# pages, excluding purgeable memory. Read the page size (16 KiB on Apple Silicon,
# 4 KiB on Intel), and count the compressor's footprint, not its logical pages.
# Binary GB keeps installed 24 GiB RAM displayed as 24.000 GB.
SAMPLE="$(awk -F ': *' '
  /^Mach Virtual Memory Statistics:/ {
    match($0, /[0-9]+/)
    page_size = substr($0, RSTART, RLENGTH) + 0
  }
  /^(Anonymous pages|Pages wired down|Pages occupied by compressor|Pages purgeable):/ {
    pages[$1] = $2 + 0
  }
  /^hw.memsize:/ { total = $2 + 0 }
  /^vm.swapusage:/ {
    if (match($2, /used = [0-9.]+[KMGT]/)) {
      value = substr($2, RSTART + 7, RLENGTH - 7)
      unit = substr(value, length(value), 1)
      scale = 1024 ^ index("KMGT", unit)
      swap = (value + 0) * scale
      have_swap = 1
    }
  }
  END {
    if (page_size <= 0 || total <= 0 || !have_swap ||
        !("Anonymous pages" in pages) || !("Pages wired down" in pages) ||
        !("Pages occupied by compressor" in pages) || !("Pages purgeable" in pages)) exit 1
    used = (pages["Anonymous pages"] + pages["Pages wired down"] + \
            pages["Pages occupied by compressor"] - pages["Pages purgeable"]) * page_size
    if (used < 0 || used > total) exit 1
    printf "%.3f / %.3f GB|%.3f GB\n", used / 1073741824, total / 1073741824, swap / 1073741824
  }
' <<< "$VM_STATS
$SYSTEM_STATS")" || unavailable
IFS='|' read -r LABEL SWAP <<< "$SAMPLE"

case "$PRESSURE" in
  1) PRESSURE_LABEL=Normal; COLOR="$COLOR_CHARGING" ;;
  2) PRESSURE_LABEL=Warning; COLOR="$COLOR_CAUTION" ;;
  4) PRESSURE_LABEL=Critical; COLOR="$COLOR_WARNING" ;;
  *) PRESSURE_LABEL=Unknown; COLOR="$COLOR_INACTIVE" ;;
esac

sketchybar --set "$NAME" label="$LABEL" icon.color="$COLOR" \
  --set memory.swap label="Swap: $SWAP" \
  --set memory.pressure label="Pressure: $PRESSURE_LABEL" label.color="$COLOR"
