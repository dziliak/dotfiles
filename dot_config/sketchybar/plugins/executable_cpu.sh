#!/usr/bin/env bash

CPU="$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.0f", s}')"
CORES="$(sysctl -n hw.ncpu)"
LOAD=$((CPU / CORES))

sketchybar --set "$NAME" label="${LOAD}%"
