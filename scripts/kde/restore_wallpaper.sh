#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_STORAGE="/tmp/wallpaper"

# Check if storage file exists
if [[ ! -f "$WALLPAPER_STORAGE" ]]; then
    echo "Error: Wallpaper storage file not found: $WALLPAPER_STORAGE"
    exit 1
fi

# Read the clean wallpaper path
WALLPAPER_PATH=$(cat "$WALLPAPER_STORAGE")

# Check if wallpaper file exists
if [[ ! -f "$WALLPAPER_PATH" ]]; then
    echo "Error: Wallpaper image not found: $WALLPAPER_PATH"
    exit 1
fi

echo "Restoring wallpaper: $WALLPAPER_PATH"
plasma-apply-wallpaperimage "$WALLPAPER_PATH"
