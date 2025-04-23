#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CACHE_DIR="$HOME/.cache/wal"


SOURCE_FILE="$CACHE_DIR/colors-konsole.colorscheme"
TARGET_DIR="$HOME/.local/share/konsole"
TARGET_FILE="$TARGET_DIR/pywal-konsole-theme.colorscheme"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE" && echo "Copied $SOURCE_FILE to $TARGET_FILE"

