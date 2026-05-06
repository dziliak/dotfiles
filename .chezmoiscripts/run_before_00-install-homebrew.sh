#!/usr/bin/env bash
set -euo pipefail

# Only run on macOS.
if [[ "$(uname -s)" != "Darwin" ]]; then
  exit 0
fi

# Apple Silicon Homebrew path.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  exit 0
fi

# Intel Mac Homebrew path.
if [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
  exit 0
fi

echo "Homebrew not found. Installing Homebrew..."

NONINTERACTIVE=1 /bin/bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Make brew available for the rest of this chezmoi apply.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  echo "Homebrew install completed, but brew was not found in the expected paths." >&2
  exit 1
fi

echo "Homebrew installed successfully."
