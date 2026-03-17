#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CACHE_DIR="$HOME/.cache/wal"

SOURCE_CONFIG_FILE="$CACHE_DIR/colors-lnav.json"
SOURCE_FORMAT_FILE="$CACHE_DIR/lnav-java-pipe-log.json"

TARGET_CONFIG_DIR_1="$HOME/.config/lnav/configs/installed"
TARGET_CONFIG_DIR_2="$HOME/.lnav/configs/installed"
TARGET_CONFIG_FILE_1="$TARGET_CONFIG_DIR_1/pywal-lnav.json"
TARGET_CONFIG_FILE_2="$TARGET_CONFIG_DIR_2/pywal-lnav.json"

TARGET_FORMAT_DIR_1="$HOME/.config/lnav/formats/installed"
TARGET_FORMAT_DIR_2="$HOME/.lnav/formats/installed"
TARGET_FORMAT_FILE_1="$TARGET_FORMAT_DIR_1/java-pipe-log.json"
TARGET_FORMAT_FILE_2="$TARGET_FORMAT_DIR_2/java-pipe-log.json"

# Create target directories if they don't exist
mkdir -p "$TARGET_CONFIG_DIR_1" "$TARGET_CONFIG_DIR_2" "$TARGET_FORMAT_DIR_1" "$TARGET_FORMAT_DIR_2"

cp "$SOURCE_CONFIG_FILE" "$TARGET_CONFIG_FILE_1" && echo "Copied $SOURCE_CONFIG_FILE to $TARGET_CONFIG_FILE_1"
cp "$SOURCE_CONFIG_FILE" "$TARGET_CONFIG_FILE_2" && echo "Copied $SOURCE_CONFIG_FILE to $TARGET_CONFIG_FILE_2"
cp "$SOURCE_FORMAT_FILE" "$TARGET_FORMAT_FILE_1" && echo "Copied $SOURCE_FORMAT_FILE to $TARGET_FORMAT_FILE_1"
cp "$SOURCE_FORMAT_FILE" "$TARGET_FORMAT_FILE_2" && echo "Copied $SOURCE_FORMAT_FILE to $TARGET_FORMAT_FILE_2"
