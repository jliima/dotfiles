#!/usr/bin/env bash
set -eu

CACHE_DIR="$HOME/.cache/wal"

SOURCE_FILE="$CACHE_DIR/colors-spicetify.ini"
TARGET_DIR="$HOME/.config/spicetify/Themes/pywal-theme"
TARGET_FILE="$TARGET_DIR/color.ini"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT

# Build the target content and only apply if it changed.
sed 's/#//g' "$SOURCE_FILE" > "$TEMP_FILE"

if [[ ! -f "$TARGET_FILE" ]] || ! cmp -s "$TEMP_FILE" "$TARGET_FILE"; then
  echo "Spicetify: theme changed, updating color.ini and applying..."
  cp "$TEMP_FILE" "$TARGET_FILE"
  spicetify apply --no-restart
  echo "Spicetify: apply complete."
else
  echo "Spicetify: no theme changes detected, skipping apply."
fi
