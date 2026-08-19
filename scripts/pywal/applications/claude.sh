#!/usr/bin/env bash
set -eu

CACHE_DIR="$HOME/.cache/wal"

SOURCE_FILE="$CACHE_DIR/colors-claude.json"
TARGET_DIR="$HOME/.claude/themes"
TARGET_FILE="$TARGET_DIR/pywal-claude.json"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE" && echo "Copied $SOURCE_FILE to $TARGET_FILE"

# Claude Code watches ~/.claude/themes/ for changes and applies them live,
# so no restart/reload step is needed here.
