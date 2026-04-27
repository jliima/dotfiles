#!/usr/bin/env bash
set -eu

CACHE_DIR="$HOME/.cache/wal"
OBSIDIAN_DIR="$HOME/Obsidian/.config/.obsidian-desktop"

# Theme
SOURCE_THEME="$CACHE_DIR/colors-obsidian.css"
TARGET_THEME_DIR="$OBSIDIAN_DIR/themes/PywalColors"
TARGET_THEME="$TARGET_THEME_DIR/theme.css"

# PDF Export Darkmode snippet
SOURCE_PDF="$CACHE_DIR/colors-obsidian-PDF-Export-Darkmode.css"
TARGET_SNIPPETS_DIR="$OBSIDIAN_DIR/snippets"
TARGET_PDF="$TARGET_SNIPPETS_DIR/PDF-Export-Darkmode.css"

mkdir -p "$TARGET_THEME_DIR" "$TARGET_SNIPPETS_DIR"
cp "$SOURCE_THEME" "$TARGET_THEME" && echo "Copied $SOURCE_THEME to $TARGET_THEME"
cp "$SOURCE_PDF" "$TARGET_PDF" && echo "Copied $SOURCE_PDF to $TARGET_PDF"
