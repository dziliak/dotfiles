#!/bin/bash
# Sony WH-1000XM4 item: battery in the bar, settings in the popup. All headset I/O goes through xm4ctl.

source "${CONFIG_DIR:-$(cd "$(dirname "$0")/.." && pwd)}/plugins/common.sh"
XM4="${XM4CTL:-$HOME/.local/bin/xm4ctl}"
export XM4_MAC="${XM4_MAC:-80:99:E7:95:85:71}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/Library/Caches}/sketchybar"
CACHE="$CACHE_DIR/headphones.json"
ITEM=headphones
STATUS=""

have_xm4() { "$XM4" connected 2>/dev/null; }
load() { [[ -s "$CACHE" ]] && STATUS="$(<"$CACHE")"; [[ -n "$STATUS" ]]; }
store() {
  mkdir -p "$CACHE_DIR" || return 1
  local tmp; tmp="$(mktemp "$CACHE.XXXXXX")" || return 1
  printf '%s\n' "$STATUS" > "$tmp" && mv -f "$tmp" "$CACHE"
}
fetch() { local out; out="$("$XM4" status)" || return $?; STATUS="$out"; store; }
cache_age() { local m; m="$(stat -f %m "$CACHE" 2>/dev/null)" || { echo 999999; return; }; echo $(( $(date +%s) - m )); }

# While the headset is connected this item stands in for the volume item: the volume item is
# hidden and scrolls over this one are forwarded to volume.sh (run as the hidden `volume` item).
run_volume() { NAME=volume "$CONFIG_DIR/plugins/volume.sh"; }

# Show the volume on this item for a moment after a change, then fall back to the battery.
# Only the newest readout's timer redraws, so a burst of scroll events settles cleanly.
show_volume() {
  local vicon vol
  IFS=$'\t' read -r vicon vol < <(sketchybar --query volume | jq -r '[.icon.value, .label.value] | @tsv' 2>/dev/null)
  [[ -n "$vol" ]] || return 0
  sketchybar --set "$ITEM" icon="$vicon" label="$vol" label.color="$COLOR_TEXT"
  local token="$CACHE_DIR/headphones.volume_token"
  echo "$$" > "$token"
  ( sleep 2; [[ "$(cat "$token" 2>/dev/null)" == "$$" ]] && { load; draw_bar; } ) >/dev/null 2>&1 &
}

draw_bar() {
  if [[ -z "$STATUS" ]]; then
    sketchybar --set "$ITEM" drawing=on icon="󰋋" label="!" label.color="$COLOR_WARNING" --set volume drawing=off
    return
  fi
  local pct charging color="$COLOR_TEXT"
  IFS=$'\t' read -r pct charging < <(jq -r '[(.battery.percent // "?"), (.battery.charging // false)] | @tsv' <<< "$STATUS")
  if [[ "$charging" == true ]]; then color="$COLOR_CHARGING"
  elif [[ "$pct" =~ ^[0-9]+$ ]] && ((pct < 10)); then color="$COLOR_WARNING"
  elif [[ "$pct" =~ ^[0-9]+$ ]] && ((pct < LOW_BATTERY_PERCENT)); then color="$COLOR_CAUTION"
  fi
  sketchybar --set "$ITEM" drawing=on icon="󰋋" label="${pct}%" label.color="$color" --set volume drawing=off
}

tick() {
  if ! have_xm4; then
    sketchybar --set "$ITEM" drawing=off popup.drawing=off --set volume drawing=on
    return
  fi
  case "${SENDER:-}" in
    mouse.scrolled | volume_change) run_volume; show_volume; return ;;
  esac
  if [[ "${SENDER:-}" == system_woke || "${SENDER:-}" == forced ]] || (( $(cache_age) > 300 )); then
    fetch || STATUS=""
  else
    load || fetch || STATUS=""
  fi
  draw_bar
}

# Device rows stay read-only until the fork's V1 connect/disconnect patch has passed its hardware check.
DEVICES_WRITABLE=false

onoff() { case "$1" in true) echo on ;; false) echo off ;; *) echo "?" ;; esac; }
signed() { [[ "$1" =~ ^[0-9]+$ && "$1" != 0 ]] && echo "+$1" || echo "$1"; }

# Fields are joined with the unit separator: tabs in IFS merge, so an empty name would shift every later field.
US=$'\x1f'
stale_popup() { sketchybar --set headphones.header label="!" label.color="$COLOR_WARNING"; }

draw_popup() {
  [[ -n "$STATUS" ]] || return
  local pct chg codec mode amb voice s2c dsee conn touch preset pname cb b1 b2 b3 b4 b5
  # `v` keeps false as false: jq's // would turn a false boolean into the fallback.
  IFS=$US read -r pct chg codec mode amb voice s2c dsee conn touch preset pname cb b1 b2 b3 b4 b5 < <(jq -r --arg us "$US" '
    def v(d): if . == null then d else . end;
    [(.battery.percent | v("?")), (.battery.charging | v(false)), (.codec | v("?")), (.noise.mode | v("?")),
     (.noise.ambient | v("-")), (.noise.voice | v(false)), (.s2c | v("?")), (.dsee | v("?")), (.connection | v("?")),
     (.touch | v("?")), (.eq.preset | v("-")), (.eq.preset_name | v("?")), (.eq.clear_bass | v(0)),
     (.eq.bands[0] | v(0)), (.eq.bands[1] | v(0)), (.eq.bands[2] | v(0)), (.eq.bands[3] | v(0)), (.eq.bands[4] | v(0))] | map(tostring) | join($us)' <<< "$STATUS")
  local charging_txt="" mtxt dim="$COLOR_TEXT" amb_pct=0 ctxt
  [[ "$chg" == true ]] && charging_txt=" charging"
  case "$mode" in nc) mtxt="Noise cancelling" ;; ambient) mtxt="Ambient sound" ;; off) mtxt="Off" ;; *) mtxt="?" ;; esac
  [[ "$mode" != ambient ]] && dim="$COLOR_INACTIVE"
  [[ "$amb" =~ ^[0-9]+$ ]] && amb_pct=$((amb * 5))
  case "$conn" in quality) ctxt="Sound quality" ;; stable) ctxt="Stable connection" ;; *) ctxt="?" ;; esac
  local args=(
    --set headphones.header label="${pct}%${charging_txt} · $codec"
    --set headphones.mode label="$mtxt" label.color="$COLOR_TEXT"
    --set headphones.ambient slider.percentage="$amb_pct" label="$amb" label.color="$dim" icon.color="$dim"
    --set headphones.voice label="$(onoff "$voice")" label.color="$dim" icon.color="$dim"
    --set headphones.s2c label="$(onoff "$s2c")" label.color="$COLOR_TEXT"
    --set headphones.dsee label="$(onoff "$dsee")" label.color="$COLOR_TEXT"
    --set headphones.connection label="$ctxt" label.color="$COLOR_TEXT"
    --set headphones.touch label="$(onoff "$touch")" label.color="$COLOR_TEXT"
    --set headphones.eq label="$pname" label.color="$COLOR_TEXT"
    --set headphones.clearbass slider.percentage=$(((cb + 10) * 5)) label="$(signed "$cb")" label.color="$COLOR_TEXT"
  )
  local i=1 b
  for b in "$b1" "$b2" "$b3" "$b4" "$b5"; do
    args+=(--set "headphones.band.$i" slider.percentage=$(((b + 10) * 5)) label="$(signed "$b")" label.color="$COLOR_TEXT")
    i=$((i + 1))
  done
  local id name
  for id in $(seq 0 29); do args+=(--set "headphones.preset.$id" drawing=off); done
  while IFS=$US read -r id name; do
    [[ "$id" =~ ^[0-9]+$ ]] && ((id <= 29)) || continue
    local color="$COLOR_TEXT"; [[ "$id" == "$preset" ]] && color="$COLOR_CHARGING"
    args+=(--set "headphones.preset.$id" drawing=on label="$name" label.color="$color")
  done < <(jq -r --arg us "$US" '.eq.presets[]? | [.id, .name] | map(tostring) | join($us)' <<< "$STATUS")
  for i in 0 1 2 3 4 5 6 7; do args+=(--set "headphones.device.$i" drawing=off); done
  local mac connected playing self
  i=0
  while IFS=$US read -r mac name connected playing self; do
    ((i <= 7)) || break
    local icon="○ $name" value=connect color="$COLOR_INACTIVE" click="$PLUGIN_DIR/headphones.sh device $i"
    if [[ "$connected" == true ]]; then
      icon="● $name"; color="$COLOR_TEXT"; value=connected
      [[ "$playing" == true ]] && value=playing
    fi
    [[ "$self" == true || "$DEVICES_WRITABLE" != true ]] && click=""
    args+=(--set "headphones.device.$i" drawing=on icon="$icon" label="$value" icon.color="$color" label.color="$color" click_script="$click")
    i=$((i + 1))
  done < <(jq -r --arg us "$US" '.devices[]? | [.mac, .name, .connected, .playing, .self] | map(tostring) | join($us)' <<< "$STATUS")
  sketchybar "${args[@]}"
}

# Paint the clicked row as pending, apply through xm4ctl, redraw everything from the fresh status.
do_set() {
  local row="$1"; shift
  sketchybar --set "$row" label="…" label.color="$COLOR_INACTIVE"
  local out
  if out="$("$XM4" set "$@")"; then
    STATUS="$out"; store; draw_bar; draw_popup
  else
    sketchybar --set "$row" label="!" label.color="$COLOR_WARNING"
  fi
}

toggle() {
  local open; open="$(sketchybar --query headphones | jq -r '.popup.drawing')"
  if [[ "$open" == on ]]; then
    sketchybar --set headphones.eq popup.drawing=off --set headphones popup.drawing=off
    return
  fi
  load && draw_popup                                # cached values first, the fetch takes ~3 s
  sketchybar --set headphones popup.drawing=on
  fetch || { STATUS=""; draw_bar; stale_popup; return; }
  draw_bar; draw_popup
}

refresh() {
  [[ "${SENDER:-}" == forced ]] && return          # the bar item's own forced tick already fetched
  if fetch; then draw_bar; draw_popup; else stale_popup; fi
}

mode() {
  # Clicks (BUTTON set) and scrolls only: a click's env also carries the SENDER of the item's last script update.
  [[ -n "${BUTTON:-}" || "${SENDER:-}" == mouse.scrolled ]] || return 0
  load || return 1
  local cur step=1 i next order=(nc ambient off)
  cur="$(jq -r '.noise.mode // "nc"' <<< "$STATUS")"
  if [[ "${SENDER:-}" == mouse.scrolled ]]; then
    [[ "${SCROLL_DELTA:-0}" =~ ^[+-]?[0-9]+$ ]] || return 0
    ((SCROLL_DELTA == 0)) && return 0
    ((SCROLL_DELTA < 0)) && step=2                   # one step back == two forward in a cycle of three
  fi
  for i in 0 1 2; do [[ "${order[$i]}" == "$cur" ]] && next="${order[$(((i + step) % 3))]}"; done
  do_set headphones.mode mode "${next:-nc}"
}

toggle_key() {
  load || return 1
  local cur next
  case "$1" in
    voice) cur="$(jq -r '.noise.voice' <<< "$STATUS")" ;;
    connection) cur="$(jq -r '.connection' <<< "$STATUS")" ;;
    *) cur="$(jq -r ".[\"$1\"]" <<< "$STATUS")" ;;
  esac
  case "$cur" in true) next=off ;; false) next=on ;; quality) next=stable ;; stable) next=quality ;; *) return 1 ;; esac
  do_set "${NAME:-headphones.$1}" "$1" "$next"
}

slider() {
  [[ "${PERCENTAGE:-}" =~ ^[0-9]+$ ]] || return 1
  local steps=$(((PERCENTAGE * 20 + 50) / 100))      # 0..100 % -> 0..20
  case "$1" in
    ambient) do_set "${NAME:-headphones.ambient}" ambient "$steps" ;;
    clear-bass) do_set "${NAME:-headphones.clearbass}" clear-bass $((steps - 10)) ;;
    eq-band) do_set "${NAME:-headphones.band.$2}" eq-band "$2" $((steps - 10)) ;;
  esac
}

device() {
  load || return 1
  local mac connected self
  IFS=$'\t' read -r mac connected self < <(jq -r ".devices[$1] | [.mac, .connected, .self] | @tsv" <<< "$STATUS")
  [[ -n "$mac" && "$self" != true ]] || return 0
  if [[ "$connected" == true ]]; then do_set "headphones.device.$1" device-disconnect "$mac"
  else do_set "headphones.device.$1" device-connect "$mac"; fi
}

case "${1:-tick}" in
  tick) tick ;;
  toggle) toggle ;;
  refresh) refresh ;;
  mode) mode ;;
  toggle-key) toggle_key "$2" ;;
  slider) slider "$2" "${3:-}" ;;
  preset) sketchybar --set headphones.eq popup.drawing=off; do_set headphones.eq eq-preset "$2" ;;
  eq-menu) [[ "$(sketchybar --query headphones.eq | jq -r '.popup.drawing')" == on ]] && v=off || v=on; sketchybar --set headphones.eq popup.drawing=$v ;;
  device) device "$2" ;;
  *) echo "headphones.sh: unknown action $1" >&2; exit 1 ;;
esac
