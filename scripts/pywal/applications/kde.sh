#!/usr/bin/env bash
set -eu

CACHE_DIR="$HOME/.cache/wal"

SOURCE_FILE="$CACHE_DIR/colors-kde.colors"
TARGET_DIR="$HOME/.local/share/color-schemes"

THEME_1_NAME="Pywal-1"
THEME_2_NAME="Pywal-2"

TARGET_FILE_1="$TARGET_DIR/$THEME_1_NAME.colors"
TARGET_FILE_2="$TARGET_DIR/$THEME_2_NAME.colors"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

cp "$SOURCE_FILE" "$TARGET_FILE_1" && echo "Copied $SOURCE_FILE to $TARGET_FILE_1"
cp "$SOURCE_FILE" "$TARGET_FILE_2" && echo "Copied $SOURCE_FILE to $TARGET_FILE_2"


CURRENT_THEME=$(plasma-apply-colorscheme -l | grep '(current color scheme)' | awk -F' ' '{print $2}')

if [[ "$CURRENT_THEME" != "$THEME_1_NAME" ]]; then
    echo "Switching from $CURRENT_THEME to $THEME_1_NAME"
    plasma-apply-colorscheme "$THEME_1_NAME"
else
    echo "Switching from $CURRENT_THEME to $THEME_2_NAME"
    plasma-apply-colorscheme "$THEME_2_NAME"
fi