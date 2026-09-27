#!/usr/bin/env bash
# Claude desktop pywal theme application script.
#
# Writes the rendered theme CSS to a stable, user-owned location. The app
# itself picks it up at runtime via a one-time sudo patch of its app.asar
# (see scripts/pywal/claude-desktop-patch.sh) that reads this file and
# insertCSS()s it into the page on every load. This script never needs sudo
# and is safe to run on every pywal invocation.
set -eu

CACHE_DIR="$HOME/.cache/wal"
SOURCE_FILE="$CACHE_DIR/colors-claude-desktop.css"
TARGET_DIR="$HOME/.config/claude-desktop-theme"
TARGET_FILE="$TARGET_DIR/theme.css"

mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE" && echo "Copied $SOURCE_FILE to $TARGET_FILE"

echo "Reload the Claude window (Ctrl+R) or restart the app to see the new theme."
echo "(If colors don't change at all, the app.asar patch may not be installed yet:"
echo " run ~/dotfiles/scripts/pywal/claude-desktop-patch.sh install)"
