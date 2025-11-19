#!/usr/bin/env bash
# This script should continue on errors
# set -e
set -u

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_DIR="$(dirname "${SCRIPT_DIR}")"
WALLPAPER_DIR="~/Pictures/Wallpapers"

"$SCRIPT_DIR/kde/set-wallpaper-for-activity.py" 'Default' "${WALLPAPER_DIR}/Misc/icy-mountains-and-boat.png"
"$SCRIPT_DIR/kde/set-wallpaper-for-activity.py" 'Work' "${WALLPAPER_DIR}/Misc/firm-logo-4k.png"
"$SCRIPT_DIR/kde/set-wallpaper-for-activity.py" 'School' "${WALLPAPER_DIR}/Green/wallhaven-3lyzyv.jpg"