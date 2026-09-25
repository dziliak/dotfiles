#!/usr/bin/env bash

if [ "$SCROLL_DELTA" -gt 0 ]; then
  # scroll up → volume up
  osascript -e "set volume output volume (output volume of (get volume settings) + 5)"
else
  # scroll down → volume down
  osascript -e "set volume output volume (output volume of (get volume settings) - 5)"
fi
