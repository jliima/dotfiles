#!/usr/bin/env bash
set -eu

CACHE_DIR="$HOME/.cache/wal"

SOURCE_FILE="$CACHE_DIR/colors-obsidian.css"
TARGET_DIR_1="$HOME/Obsidian/.config/.obsidian-desktop/themes/PywalColors"
TARGET_FILE_1="$TARGET_DIR_1/theme.css"

mkdir -p "$TARGET_DIR_1"
cp "$SOURCE_FILE" "$TARGET_FILE_1" && echo "Copied $SOURCE_FILE to $TARGET_FILE_1"
