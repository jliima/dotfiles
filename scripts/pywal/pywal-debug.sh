#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
APPLICATIONS_DIR="${SCRIPT_DIR}/applications"

# Function to determine target theme
get_target_theme() {
    local themes_output
    themes_output=$(wal --theme)

    # Check which theme was last used
    if echo "$themes_output" | grep -qE 'debug-colors-1 \(last used\)'; then
        echo "debug-colors-2"
    elif echo "$themes_output" | grep -qE 'debug-colors-2 \(last used\)'; then
        echo "debug-colors-1"
    else
        echo "debug-colors-1"
    fi
}

TARGET_THEME=$(get_target_theme)

. "$SCRIPT_DIR/run-pywal.sh" --theme "$TARGET_THEME"
