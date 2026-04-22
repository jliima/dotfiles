#!/usr/bin/env bash
# This script should continue on errors
# set -e
set -u

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

"$SCRIPT_DIR/kde/set-wallpaper-for-activity.py" 'Default' "${HOME}/dotfiles/wallpapers/Along-the-Lunar-Terminator_cropped.jpg"
"$SCRIPT_DIR/kde/set-wallpaper-for-activity.py" 'Work' "${WALLPAPER_DIR}/Misc/firm-logo-4k.png"
"$SCRIPT_DIR/kde/set-wallpaper-for-activity.py" 'School' "${WALLPAPER_DIR}/Green/wallhaven-3lyzyv.jpg"