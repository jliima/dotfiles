#!/usr/bin/env bash
# This script should continue on errors
# set -e
set -u

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

"$SCRIPT_DIR/set-wallpaper-for-activity.py" 'Default' "$SCRIPT_DIR/../../wallpapers/wallhaven-3lyzyv_pare.jpg"
"$SCRIPT_DIR/set-wallpaper-for-activity.py" 'Work' "${WALLPAPER_DIR}/Firm/firm-hairpin-3840x2160.png"
"$SCRIPT_DIR/set-wallpaper-for-activity.py" 'School' "${WALLPAPER_DIR}/Green/wallhaven-3lyzyv.jpg"