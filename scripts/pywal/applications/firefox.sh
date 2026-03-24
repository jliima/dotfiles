#!/usr/bin/env bash
set -eu

CACHE_DIR="$HOME/.cache/wal"

SOURCE_FILE="$CACHE_DIR/colors.css"
TARGET_DIR="$HOME/.mozilla/firefox/chrome/pywal"
TARGET_FILE="$TARGET_DIR/colors.css"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE" && echo "Copied $SOURCE_FILE to $TARGET_FILE"
