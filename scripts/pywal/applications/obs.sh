#!/usr/bin/env bash
set -eu

CACHE_DIR="$HOME/.cache/wal"

SOURCE_FILE="$CACHE_DIR/colors-obs.ovt"
TARGET_DIR="$HOME/.var/app/com.obsproject.Studio/config/obs-studio/themes"
TARGET_FILE="$TARGET_DIR/Pywal.ovt"

mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE" && echo "Copied $SOURCE_FILE to $TARGET_FILE"
