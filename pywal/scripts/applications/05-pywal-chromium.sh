#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CACHE_DIR="$HOME/.cache/wal"


SOURCE_FILE="$CACHE_DIR/colors-chrome.json"
TARGET_DIR="$HOME/.config/chromium/pywal-theme"
TARGET_FILE="$TARGET_DIR/manifest.json"

#killall chrome

# Check if Chromium is running and kill if needed
restart_chromium=""
if pgrep -x chrome >/dev/null; then
    echo "Killing existing Chromium instances"
    pkill -x chrome
    restart_chromium=1
fi

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE" && echo "Copied $SOURCE_FILE to $TARGET_FILE"

rm -f "$TARGET_DIR/Cached Theme.pak"

# TODO Check what URLs were open and reopen those.

#/snap/bin/chromium --disable-search-engine-choice-screen --no-default-browser-check --no-first-run --disable-default-apps --disable-popup-blocking

# Only relaunch if we killed existing instances
if [ -n "${restart_chromium:-}" ]; then
    echo "Restarting Chromium"
    # Fully detach from terminal and suppress all output
    nohup /snap/bin/chromium \
        --disable-search-engine-choice-screen \
        --no-default-browser-check \
        --no-first-run \
        --disable-default-apps \
        --disable-popup-blocking >/dev/null 2>&1 &
    disown
fi
