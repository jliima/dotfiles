#!/usr/bin/env bash
# Install / refresh the Copilot Usage plasmoid from this project.
# Symlinks the package into Plasma's plasmoid dir, clears the compiled QML
# cache, and restarts plasmashell so edits to package/ actually show up.
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [COPILOT_HOME]

  Install / refresh the Copilot Usage plasmoid.

Arguments:
  COPILOT_HOME   Optional path to a non-default Copilot CLI config dir
                 (i.e. the COPILOT_HOME you log in with). Remembered in
                 ~/.config/copilot-usage-widget/copilot_home so the widget
                 keeps reading it on future refreshes.

  With no argument, the widget reads the default profile: ~/.copilot
  (and, if a custom path was set before, running with no argument reverts
  to the default).

Examples:
  $(basename "$0")                    # default profile: ~/.copilot
  $(basename "$0") ~/.copilot-work    # a custom COPILOT_HOME instead
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/com.jliima.copilotusage"
HOME_OVERRIDE_FILE="$HOME/.config/copilot-usage-widget/copilot_home"

mkdir -p "$(dirname "$HOME_OVERRIDE_FILE")"
if [ $# -ge 1 ]; then
  # Expand a leading ~ ourselves — it only auto-expands when unquoted at
  # the shell, not when it arrives through "$1".
  CUSTOM_HOME="${1/#\~/$HOME}"
  echo "$CUSTOM_HOME" > "$HOME_OVERRIDE_FILE"
  echo "Using custom COPILOT_HOME: $CUSTOM_HOME"
else
  rm -f "$HOME_OVERRIDE_FILE"
  echo "Using default COPILOT_HOME: $HOME/.copilot"
fi

mkdir -p "$(dirname "$PLASMOID_DIR")"

# package/ -> plasmoids/com.jliima.copilotusage  (live = source)
rm -rf "$PLASMOID_DIR"
ln -s "$HERE/package" "$PLASMOID_DIR"

# Plasma caches *compiled* QML; without this, source edits won't load.
rm -rf "$HOME/.cache/plasmashell/qmlcache"

# Restart the shell to pick everything up.
if systemctl --user list-units --type=service 2>/dev/null | grep -q plasma-plasmashell; then
  systemctl --user restart plasma-plasmashell.service
else
  kquitapp6 plasmashell 2>/dev/null || true
  sleep 1
  (kstart plasmashell >/dev/null 2>&1 &)
fi

echo "Installed via symlink. Live install -> $HERE/package"
echo "If it's not on a panel yet: right-click panel -> Add Widgets -> 'Copilot Usage'."
