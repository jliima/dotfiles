#!/usr/bin/env bash
# This script should continue on errors
# set -e
set -u

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_DIR="$(dirname "${SCRIPT_DIR}")"
WALLPAPER_DIR="~/Pictures/Wallpapers"

#if command -v kwallet-query &> /dev/null; then
#  kwallet-query -l kdewallet > /dev/null
#fi

#echo "Starting SSH agent configuration script."
#SETUP_AGENT="${REPO_DIR}/ssh/setup_agent.sh"
#if [ -f "${SETUP_AGENT}" ]; then
#  "${SETUP_AGENT}" private-scripts
#fi


# Syncthing and cloud services should be started as early as possible to ensure
# that the user does not modify files before they are synced.
if command -v syncthing >/dev/null 2>&1; then
  syncthing --no-browser &
fi

#if command -v telegram-desktop >/dev/null 2>&1; then
#  echo "Starting Telegram"
#  telegram-desktop -startintray &
#fi

"$SCRIPT_DIR/kde/set-wallpaper-for-activity.py" 'Default' "${WALLPAPER_DIR}/Misc/icy-mountains-and-boat.png" >/dev/null 2>&1
"$SCRIPT_DIR/kde/set-wallpaper-for-activity.py" 'Work' "${WALLPAPER_DIR}/Misc/firm-logo-4k.png" >/dev/null 2>&1
"$SCRIPT_DIR/kde/set-wallpaper-for-activity.py" 'School' "${WALLPAPER_DIR}/Green/1462041571377.jpg" >/dev/null 2>&1