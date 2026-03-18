#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CACHE_DIR="$HOME/.cache/wal"

SOURCE_CONFIG_FILE="$CACHE_DIR/colors-lnav.json"
SOURCE_FORMAT_FILE="$CACHE_DIR/lnav-java-pipe-log.json"

TARGET_CONFIG_DIR="$HOME/.config/lnav/configs/installed"
TARGET_CONFIG_FILE="$TARGET_CONFIG_DIR/pywal-lnav.json"

TARGET_FORMAT_DIR="$HOME/.config/lnav/formats/installed"
TARGET_FORMAT_FILE="$TARGET_FORMAT_DIR/java-pipe-log.json"

# Create target directories if they don't exist
mkdir -p "$TARGET_CONFIG_DIR" "$TARGET_FORMAT_DIR"

cp "$SOURCE_CONFIG_FILE" "$TARGET_CONFIG_FILE" && echo "Copied $SOURCE_CONFIG_FILE to $TARGET_CONFIG_FILE"
cp "$SOURCE_FORMAT_FILE" "$TARGET_FORMAT_FILE" && echo "Copied $SOURCE_FORMAT_FILE to $TARGET_FORMAT_FILE"
