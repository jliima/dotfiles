#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        focus-or-launch.sh
# Description: Bring an existing window of an app to the current virtual
#              desktop and activate it, or launch a new instance if none
#              exists.
#
# Details:
#   Uses kdotool (KWin scripting bridge, Wayland-compatible) to search for a
#   window whose class matches CLASS_REGEX. If one is found, it is moved to
#   the current virtual desktop and activated (raised + focused). Otherwise
#   the given command is launched as a new, detached process.
# ------------------------------------------------------------------------------
set -euo pipefail

# KDE's global-shortcut launcher runs this with a minimal PATH that doesn't
# include ~/.local/bin, so kdotool must be referenced by an absolute path.
KDOTOOL="$HOME/.local/bin/kdotool"

usage() {
  cat <<EOF
Usage: $(basename "$0") <class-regex> -- <command> [args...]

  Focuses an existing window matching <class-regex> (moving it to the
  current virtual desktop first), or launches <command> if no matching
  window is open.

Example:
  $(basename "$0") '^org\.kde\.dolphin\$' -- dolphin
EOF
}

case "${1:-}" in
  -h|--help|"") usage; exit 0 ;;
esac

CLASS_REGEX="$1"
shift

if [ "${1:-}" != "--" ]; then
  echo "Error: expected -- before the launch command" >&2
  usage
  exit 1
fi
shift

if [ "$#" -eq 0 ]; then
  echo "Error: no launch command given" >&2
  usage
  exit 1
fi

WINDOW_ID="$("$KDOTOOL" search --class "$CLASS_REGEX" --limit 1 2>/dev/null || true)"

if [ -n "$WINDOW_ID" ]; then
  "$KDOTOOL" set_desktop_for_window "$WINDOW_ID" current_desktop
  "$KDOTOOL" windowactivate "$WINDOW_ID"
else
  setsid -f "$@" >/dev/null 2>&1
fi
