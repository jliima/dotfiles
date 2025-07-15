#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CACHE_DIR="$HOME/.cache/wal"


SOURCE_FILE="$CACHE_DIR/colors-obsidian.css"
TARGET_DIR_1="$HOME/Obsidian/default_vault/.obsidian/themes/PywalColors"
TARGET_DIR_2="$HOME/Obsidian/work_vault/.obsidian/themes/PywalColors"
TARGET_FILE_1="$TARGET_DIR_1/theme.css"
TARGET_FILE_2="$TARGET_DIR_2/theme.css"

# Create target directories if it doesn't exist
mkdir -p "$TARGET_DIR_1"
mkdir -p "$TARGET_DIR_2"
cp "$SOURCE_FILE" "$TARGET_FILE_1" && echo "Copied $SOURCE_FILE to $TARGET_FILE_1"
cp "$SOURCE_FILE" "$TARGET_FILE_2" && echo "Copied $SOURCE_FILE to $TARGET_FILE_2"
