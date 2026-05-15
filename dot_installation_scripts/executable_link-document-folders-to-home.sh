#!/usr/bin/env zsh
set -euo pipefail

src="$HOME/Documents"
dst="$HOME"

folders=(
  "Julia"
  "Lua"
  "Projects"
  "Python"
  "Python Git"
  "Python Venv"
  "References"
  "Swift"
)

for name in "${folders[@]}"; do
  item="$src/$name"
  target="$dst/$name"

  if [[ ! -d "$item" ]]; then
    echo "Missing folder: $item"
  elif [[ -e "$target" || -L "$target" ]]; then
    echo "Skipping: $target already exists"
  else
    ln -s "$item" "$target"
    echo "Linked: $target -> $item"
  fi
done
