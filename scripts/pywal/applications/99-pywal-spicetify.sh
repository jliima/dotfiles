#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CACHE_DIR="$HOME/.cache/wal"

SOURCE_FILE="$CACHE_DIR/colors-spicetify.ini"
TARGET_DIR="$HOME/.config/spicetify/Themes/pywal-theme"
TARGET_FILE="$TARGET_DIR/color.ini"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE"

# Remove all '#' characters from the target file
sed -i 's/#//g' "$TARGET_FILE"

spicetify apply
