#!/bin/bash
# Shared helpers; this file is sourced, not registered as an item script.
CONFIG_DIR="${CONFIG_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$CONFIG_DIR/settings.sh"

init_state() {
  CACHE_DIR="${XDG_CACHE_HOME:-$HOME/Library/Caches}/sketchybar"
  mkdir -p "$CACHE_DIR" || return 1
  local key="${NAME:-$1}"
  STATE_FILE="$CACHE_DIR/${key//[^a-zA-Z0-9_.-]/_}.state"
}

# Replace the entire sample so readers never see a partially written record.
write_state() {
  local temporary
  temporary="$(mktemp "$STATE_FILE.XXXXXX")" || return 1
  if printf '%s\n' "$*" > "$temporary" && mv -f "$temporary" "$STATE_FILE"; then
    return 0
  fi
  rm -f "$temporary"
  return 1
}

# Bound values before shell arithmetic (also rejects signs and expressions).
is_counter() {
  [[ "$1" =~ ^(0|[1-9][0-9]{0,15})$ ]]
}
