#!/usr/bin/env bash
set -eu

CACHE_DIR="$HOME/.cache/wal"

SOURCE_FILE="$CACHE_DIR/colors-obsidian.css"
TARGET_DIR_1="$HOME/Obsidian/.config/.obsidian-desktop/themes/PywalColors"
TARGET_DIR_2="$HOME/Obsidian/.config/.obsidian-desktop/themes/PywalColors"
TARGET_DIR_3="$HOME/Obsidian/.config/.obsidian-desktop/themes/PywalColors"
TARGET_FILE_1="$TARGET_DIR_1/theme.css"
TARGET_FILE_2="$TARGET_DIR_2/theme.css"
TARGET_FILE_3="$TARGET_DIR_3/theme.css"

# Create target directories if it doesn't exist
mkdir -p "$TARGET_DIR_1"
mkdir -p "$TARGET_DIR_2"
mkdir -p "$TARGET_DIR_3"
cp "$SOURCE_FILE" "$TARGET_FILE_1" && echo "Copied $SOURCE_FILE to $TARGET_FILE_1"
cp "$SOURCE_FILE" "$TARGET_FILE_2" && echo "Copied $SOURCE_FILE to $TARGET_FILE_2"
cp "$SOURCE_FILE" "$TARGET_FILE_3" && echo "Copied $SOURCE_FILE to $TARGET_FILE_3"
