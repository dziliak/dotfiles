#!/bin/bash
# Shared appearance and update intervals. Sourced by sketchybarrc and plugins.
FONT_FAMILY="JetBrainsMono NFM"
FONT_ICON="$FONT_FAMILY:Regular:18.0"
FONT_LABEL="$FONT_FAMILY:Regular:13.0"
FONT_SMALL="$FONT_FAMILY:Regular:11.0"
FONT_TITLE="$FONT_FAMILY:Bold:12.0"

COLOR_TEXT=0xffffffff
COLOR_DARK=0xff000000
COLOR_BAR=0x40000000
COLOR_POPUP=0xcc1e1e2e
COLOR_VISIBLE=0x99ffffff
COLOR_OCCUPIED=0x40ffffff
COLOR_INACTIVE=0x88ffffff
COLOR_WARNING=0xffff6b6b
COLOR_CHARGING=0xffa6e3a1
COLOR_CAUTION=0xfff9e2af

# Keep these names in sync with AeroSpace's persistent-workspaces and bindings.
WORKSPACES=(1 2 3 4 5 6 7 8 9 0)
NETWORK_INTERVAL=3
CPU_INTERVAL=3
MEMORY_INTERVAL=3
WORKSPACE_INTERVAL=30
VOLUME_INTERVAL=30
VOLUME_STEP=5
LOW_BATTERY_PERCENT=20

# Sony WH-1000XM4 Bluetooth address for the headphones item (xm4ctl).
XM4_MAC=80:99:E7:95:85:71
