#!/usr/bin/env zsh

set -euo pipefail

borg-backup

usb-backup

diskutil eject /dev/disk4
