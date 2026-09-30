#!/usr/bin/env bash
# Claude desktop pywal theme application script.
#
# Writes the rendered theme CSS to a stable, user-owned location. The app
# itself picks it up at runtime via a sudo patch of its app.asar (see
# scripts/pywal/claude-desktop-patch.sh) that reads this file and
# insertCSS()s it into the page on every load.
#
# Every apt upgrade of claude-desktop replaces app.asar with an unpatched
# copy, so this also checks the patch and reinstalls it when missing. run-pywal
# runs this script without a terminal, so the reinstall asks for the password
# through a polkit dialog (pkexec) unless sudo already has cached credentials.
set -eu

CACHE_DIR="$HOME/.cache/wal"
SOURCE_FILE="$CACHE_DIR/colors-claude-desktop.css"
TARGET_DIR="$HOME/.config/claude-desktop-theme"
TARGET_FILE="$TARGET_DIR/theme.css"
PATCH_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/claude-desktop-patch.sh"

notify() {
  command -v notify-send >/dev/null && notify-send -a pywal -i claude-desktop "Claude theme" "$1" || true
}

mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE" && echo "Copied $SOURCE_FILE to $TARGET_FILE"

if ! dpkg-query -W claude-desktop >/dev/null 2>&1; then
  echo "claude-desktop is not installed, skipping the app.asar patch."
  exit 0
fi

if "$PATCH_SCRIPT" check; then
  echo "Reload the Claude window (Ctrl+R) or restart the app to see the new theme."
  exit 0
fi

echo "Installing the app.asar theme patch..."
if sudo -n true 2>/dev/null; then
  "$PATCH_SCRIPT" install
elif [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]] && command -v pkexec >/dev/null; then
  pkexec "$PATCH_SCRIPT" install
elif [[ -t 0 ]]; then
  "$PATCH_SCRIPT" install
else
  notify "app.asar is not patched. Run $PATCH_SCRIPT install"
  echo "Error: cannot ask for a password here. Run: $PATCH_SCRIPT install" >&2
  exit 1
fi

notify "Theme patch installed. Restart Claude to apply it."
echo "Patch installed. Restart claude-desktop to see the theme."
